#![feature(proc_macro, wasm_custom_section, wasm_import_module)]

mod util;

#[macro_use]
extern crate cfg_if;

extern crate regex;

cfg_if! {
    if #[cfg(not(target_arch = "wasm32"))] {
        extern crate libc;
        use std::ffi::CStr;
        use std::ffi::CString;
        use libc::c_char;

        // NOTE(mroberts): See below.
        // type InStr = *const c_char;
        // type OutStr = *mut c_char;

        fn from_in_str(input: InStr) -> String {
            let c_input = unsafe { CStr::from_ptr(input) };
            c_input.to_str().unwrap().to_owned()
        }

        fn to_out_str(output: String) -> OutStr {
            CString::new(output).unwrap().into_raw()
        }
    } else {
        extern crate wasm_bindgen;
        use wasm_bindgen::prelude::*;

        type InStr = String;
        type OutStr = String;

        fn from_in_str(input: InStr) -> String {
            return input.to_owned();
        }

        fn to_out_str(output: String) -> OutStr {
            return output.to_owned();
        }
    }
}

#[cfg(not(target_arch = "wasm32"))]
type InStr = *const c_char;

#[cfg(not(target_arch = "wasm32"))]
type OutStr = *mut c_char;

#[cfg(not(target_arch = "wasm32"))]
#[no_mangle]
pub extern "C" fn set_bitrate_parameters(sdp: InStr, modifier: util::Modifier, max_audio_bitrate: u16, max_video_bitrate: u16) -> OutStr {
    to_out_str(util::set_bitrate_parameters(
            &mut from_in_str(sdp),
            &modifier,
            if max_audio_bitrate > 0 { Some(max_audio_bitrate) } else { None },
            if max_video_bitrate > 0 { Some(max_video_bitrate) } else { None }))
}

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub fn set_bitrate_parameters(sdp: InStr, modifier: util::Modifier, max_audio_bitrate: u16, max_video_bitrate: u16) -> OutStr {
    to_out_str(util::set_bitrate_parameters(
            &mut from_in_str(sdp),
            &modifier,
            if max_audio_bitrate > 0 { Some(max_audio_bitrate) } else { None },
            if max_video_bitrate > 0 { Some(max_video_bitrate) } else { None }))
}
