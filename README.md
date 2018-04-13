oxidation-tweek
===============

This Tweek\* project explores potential code-sharing between Twilio's C++ and
JavaScript Video SDKs using Rust, [cbindgen](https://github.com/eqrion/cbindgen),
and [wasm-bindgen](https://github.com/rustwasm/wasm-bindgen). rustc lets us
compile C and WebAssembly libraries, while cbindgen and wasm-bindgen generate
the C and JavaScript bindings, respectively. With these tools, we can write code
once in Rust and target both C++ and JavaScript! Of course there are some
gotchas with this approach. For example, WebAssembly is relatively new, file
sizes are larger than handwritten JavaScript, and there are still bugs in rustc
that require duplicating Rust source in some cases; however, at a high-level, we
_should_ find a way to re-use code, if not in this particular way.

\* "Tweek" is the name of [Twilio's internal hack week](https://venturebeat.com/2016/07/24/inside-the-hackathon-that-keeps-twilio-innovating/).

Installation
------------

### Requirements

* Cargo (and Clippy)
* cbindgen
* gcc
* make
* Node.js (8 or newer)
* Rust Nightly
* wasm-bindgen
* wasm-gc
* wasm-opt

### Usage

Run `make all` to build and run both the C and JavaScript test applications.
`make help` will show some other commands you can run.

#### Release Mode

You can build in release mode with `make release`. This passes `--release` to
Cargo, transforms the generated WebAssembly with `wasm-gc` and `wasm-opt`, and
minifies the generated JavaScript.

Resources
---------

Here are some resources that helped me along the way:

* [Day 23 - calling Rust from other languages](http://zsiciarz.github.io/24daysofrust/book/vol1/day23.html)
* [rustwasm/wasm-bindgen](https://github.com/rustwasm/wasm-bindgen)
