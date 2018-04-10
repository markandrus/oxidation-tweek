rust-c-js
=========

Here is a little toy project showing how to compile Rust code that can be called
from C or JavaScript (via WebAssembly). To set this project up, I used

* [Day 23 - calling Rust from other languages](http://zsiciarz.github.io/24daysofrust/book/vol1/day23.html)
* [rustwasm/wasm-bindgen](https://github.com/rustwasm/wasm-bindgen)

Installation
------------

### Requirements

* Cargo
* gcc
* make
* Node.js (8 or newer)
* Rust Nightly
* wasm-bindgen

### Usage

Run `make all` to build and run both the C and JavaScript test applications. You
should see each print

> Hello, World!

#### Release Mode

You can build in release mode with `make release`. This passes `--release` to
Cargo, transforms the generated WebAssembly with `wasm-gc` and `wasm-opt`, and
minifies the generated JavaScript.
