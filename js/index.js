const { Modifier, set_bitrate_parameters } = require('./lib/oxidation_tweek');

const inputSdp = `v=0\r
o=mhandley 2890844526 2890842807 IN IP4 126.16.64.4\r
s=SDP Seminar\r
i=A Seminar on the session description protocol\r
c=IN IP4 224.2.17.12/127\r
t=2873397496 2873404696\r
m=audio 49170 RTP/AVP 0\r
a=sendrecv\r
m=video 51372 RTP/AVP 31\r
a=sendrecv\r
`;

const outputSdp = set_bitrate_parameters(inputSdp, Modifier.Tias, 100, 200);

console.log(outputSdp);
