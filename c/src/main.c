#include <stdint.h>
#include <stdio.h>

#include "src/oxidation_tweek.h"

char *input_sdp = "v=0\r\n\
o=mhandley 2890844526 2890842807 IN IP4 126.16.64.4\r\n\
s=SDP Seminar\r\n\
i=A Seminar on the session description protocol\r\n\
c=IN IP4 224.2.17.12/127\r\n\
t=2873397496 2873404696\r\n\
m=audio 49170 RTP/AVP 0\r\n\
a=sendrecv\r\n\
m=video 51372 RTP/AVP 31\r\n\
a=sendrecv\r\n\
";

int main() {
    Modifier modifier = Tias;
    uint16_t max_audio_bitrate = 100;
    uint16_t max_video_bitrate = 200;
    char *output_sdp = set_bitrate_parameters(input_sdp, modifier, max_audio_bitrate, max_video_bitrate);
    printf("%s\n", output_sdp);
    free(output_sdp);
}
