extern crate regex;

use regex::Regex;

use std::collections::BTreeMap;
use std::fmt;

/// A codec name
type Codec = String;

/// A payload type
type PT = u8;

/// An SDP
type SDP = String;

/// An SDP section (session- or media-level)
type Section = String;

/// An SDP media section (an m= section)
type MediaSection = Section;

/// This value is derived from the IETF spec for JSEP, and it is used to convert
/// "b=TIAS" values in bps to "b=AS" values in kbps.
const RTCP_BITRATE: u16 = 16000;

#[allow(dead_code)]
enum Modifier {
    As,
    Tias
}

impl fmt::Display for Modifier {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(match self {
            Modifier::As => "AS",
            _ => "TIAS"
        })
    }
}

/// Create a b= line for the given max bitrate in bps. If the modifier is AS,
/// then the max bitrate will be converted to kbps using the formula specified
/// in the IETF spec for JSEP mentioned above.
///
/// # Arguments
///
/// * `modifier` - The Modifier
/// * `max_bitrate` - The max bitrate in bps
///
fn create_b_line(modifier: &Modifier, max_bitrate: u16) -> String {
    format!("\r\nb={}:{}", modifier, match modifier {
        Modifier::As => (max_bitrate + RTCP_BITRATE) / 950,
        _ => max_bitrate
    })
}

/// Create a Codec Map for the given m= section.
///
/// # Arguments
///
/// * `section` - An m= section
///
#[allow(dead_code)]
pub fn create_codec_map_for_media_section(section: &str) -> BTreeMap<Codec, Vec<PT>> {
    create_pt_to_codec_name(section).iter().fold(BTreeMap::new(), |mut codec_map, (pt, codec)| {
        codec_map
            .entry(codec.to_string())
            .and_modify(|pts| pts.push(*pt))
            .or_insert_with(|| vec![*pt]);
        codec_map
    })
}

/// Create a Map from PTs to Codecs for the given m= section.
///
/// # Arguments
///
/// * `section` - An m= section
///
fn create_pt_to_codec_name(section: &str) -> BTreeMap<PT, Codec> {
    get_payload_types_in_media_section(section).iter().fold(BTreeMap::new(), |mut pt_to_codec, pt| {
        let codec = Regex::new(&format!(r#"a=rtpmap:{} ([^/]+)"#, pt))
            .unwrap()
            .find_iter(section)
            .next()
            .map(|m| m.as_str().to_lowercase())
            .unwrap_or(match pt {
                0 => "pcmu".to_string(),
                8 => "pcma".to_string(),
                _ => "".to_string()
            });
        pt_to_codec.insert(*pt, codec);
        pt_to_codec
    })
}

/// Get the PTs present in the first line of the given m= section.
/// 
/// # Arguments
///
/// * `section` - An m= section
///
fn get_payload_types_in_media_section(section: &str) -> Vec<PT> {
    section.split("\r\n").next().map(|m_line| {
        // In "m=<kind> <port> <proto> <payload_type_1> <payload_type_2> ...
        // <payload_type_n>", the regex matches <port> and the PayloadTypes.
        Regex::new(r"([0-9]+)")
            .unwrap()
            .find_iter(m_line)
            // So we need to skip the port.
            .skip(1)
            .map(|m| m.as_str().parse::<PT>().unwrap())
            .collect()
    }).unwrap_or_else(Vec::new)
}

enum Kind {
    Audio,
    Video,
    Application
}

impl fmt::Display for Kind {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(match self {
            Kind::Audio => "audio",
            Kind::Video => "video",
            _ => "application"
        })
    }
}

#[allow(dead_code)]
enum Direction {
    SendRecv,
    SendOnly,
    RecvOnly,
    Inactive
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str(match self {
            Direction::SendRecv => "sendrecv",
            Direction::SendOnly => "sendonly",
            Direction::RecvOnly => "recvonly",
            Direction::Inactive => "inactive"
        })
    }
}

/// Get the m= sections of a particular kind and direction from an SDP.
///
/// # Arguments
///
/// * `sdp` - An SDP
/// * `kind` - An optional Kind for filtering
/// * `direction` - An optional Direction for filtering
///
fn get_media_sections(sdp: &mut SDP, kind: Option<Kind>, direction: Option<Direction>) -> (Section, Vec<MediaSection>) {
    // Chop off the trailing "\r\n".
    let len = { sdp.len() - 2 };
    sdp.truncate(len);

    let kind_str = kind.map(|s| s.to_string());
    let direction_str = direction.map(|s| format!("a={}\r\n", s));

    let mut sections = sdp.split("\r\nm=");

    // NOTE(mroberts): Unsafe
    let session = sections.next().unwrap();

    let media_sections = sections
        .filter(|section|
            kind_str.as_ref().map_or(true, |s| section.starts_with(s)) &&
            direction_str.as_ref().map_or(true, |s| section.contains(s)))
        .map(|s| s.to_string())
        .map(|s| format!("m={}", s))
        .collect();

    (session.to_string(), media_sections)
}

/// Set the specified max bitrate in the given m= section.
///
/// # Arguments
///
/// * `modifier` - The Modifier
/// * `bitrate` - The max bitrate in bps
/// * `section` - The m= section
///
fn set_bitrate_in_media_section(modifier: &Modifier, bitrate: u16, section: &str) -> MediaSection {
    format!("{}{}", section
        .split("\r\n")
        .map(|line| line.to_string())
        .filter(|line| !line.starts_with("b="))
        .collect::<Vec<_>>()
        .join("\r\n"),
        create_b_line(&modifier, bitrate))
}

/// Set maximum bitrates in a given SDP.
///
/// # Arguments
///
/// * `sdp - The SDP
/// * `modifier` - The Modifier
/// * `max_audio_bitrate` - The optional max audio bitrate in bps
/// * `max_video_bitrate` - The optional max video bitrate in bps
///
fn set_bitrate_parameters(sdp: &mut SDP, modifier: &Modifier, max_audio_bitrate: Option<u16>, max_video_bitrate: Option<u16>) -> SDP {
    let (session, mut media_sections) = get_media_sections(sdp, None, None);
    media_sections = media_sections.iter().map(|section| {
        let kind = if section.starts_with("m=audio") {
            Kind::Audio
        } else if section.starts_with("m=video") {
            Kind::Video
        } else {
            Kind::Application
        };

        let max_bitrate = match kind {
            Kind::Audio => max_audio_bitrate,
            Kind::Video => max_video_bitrate,
            _ => None
        };

        max_bitrate.as_ref().map_or(section.to_string(), |bitrate| {
            // Bitrate parameters should not be applied to m=application sections or
            // to m=audio or m=video sections that do not receive media.
            if section.contains("a=sendonly\r\n") || section.contains("a=inactive\r\n") {
                return section.to_string();
            }
            // TODO(mroberts): Fix!!!
            // set_bitrate_in_media_section(Modifier::TIAS, *bitrate, section)
            set_bitrate_in_media_section(modifier, *bitrate, section)
        })
    }).collect();
    format!("{}\r\n{}\r\n", session, media_sections.join("\r\n"))
}

pub fn do_greet(name: &str) -> String {
    // format!("Hello, {}!\nBye!", name)
    set_bitrate_parameters(&mut name.to_string(), &Modifier::Tias, Some(100), Some(200))
}

#[cfg(test)]
mod tests {
    use super::*;

    const INPUT_SDP: &str = "v=0\r
o=mhandley 2890844526 2890842807 IN IP4 126.16.64.4\r
s=SDP Seminar\r
i=A Seminar on the session description protocol\r
c=IN IP4 224.2.17.12/127\r
t=2873397496 2873404696\r
m=audio 49170 RTP/AVP 0\r
a=sendrecv\r
m=video 51372 RTP/AVP 31\r
a=sendrecv\r
";

    const EXPECTED_SDP: &str = "v=0\r
o=mhandley 2890844526 2890842807 IN IP4 126.16.64.4\r
s=SDP Seminar\r
i=A Seminar on the session description protocol\r
c=IN IP4 224.2.17.12/127\r
t=2873397496 2873404696\r
m=audio 49170 RTP/AVP 0\r
a=sendrecv\r
b=TIAS:100\r
m=video 51372 RTP/AVP 31\r
a=sendrecv\r
b=TIAS:200\r
";

    #[test]
    fn identity() {
        let actual_sdp = set_bitrate_parameters(&mut INPUT_SDP.to_string(), &Modifier::Tias, None, None);
        assert_eq!(actual_sdp, INPUT_SDP);
    }

    #[test]
    fn set_audio_and_video() {
        let actual_sdp = set_bitrate_parameters(&mut INPUT_SDP.to_string(), &Modifier::Tias, Some(100), Some(200));
        assert_eq!(actual_sdp, EXPECTED_SDP);
    }
}
