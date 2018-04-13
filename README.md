oxidation-tweek
===============

_Rust code that could possibly be shared between C++ and JavaScript SDKs_

Here is a little toy project showing how to compile Rust code that can be called
from C or JavaScript (via WebAssembly). To set this project up, I used

* [Day 23 - calling Rust from other languages](http://zsiciarz.github.io/24daysofrust/book/vol1/day23.html)
* [rustwasm/wasm-bindgen](https://github.com/rustwasm/wasm-bindgen)

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
These need to be updated to actually demonstrate what they're doing. `make help`
will show some other commands you can run.

#### Release Mode

You can build in release mode with `make release`. This passes `--release` to
Cargo, transforms the generated WebAssembly with `wasm-gc` and `wasm-opt`, and
minifies the generated JavaScript.
