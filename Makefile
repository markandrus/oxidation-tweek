all: test

clean:
	rm -rf build js/lib rust/target

build/main: c/src/main.c rust/target/debug/librust_c_js.dylib
	mkdir -p build && gcc c/src/main.c -L rust/target/debug -lrust_c_js -o build/main

js/lib/rust_c_js.js: rust/target/wasm32-unknown-unknown/debug/rust_c_js.wasm
	mkdir -p js/lib && wasm-bindgen rust/target/wasm32-unknown-unknown/debug/rust_c_js.wasm --nodejs --out-dir js/lib
	cd js && patch -p0 <rust_c_js_bg.js.patch

rust/target/debug/librust_c_js.dylib: rust/Cargo.toml rust/src/lib.rs
	cd rust && cargo build

rust/target/wasm32-unknown-unknown/debug/rust_c_js.wasm: rust/Cargo.toml rust/src/lib.rs
	cd rust && cargo build --target wasm32-unknown-unknown

test: test-c test-js

test-c: build/main
	LD_LIBRARY_PATH=rust/target/debug ./build/main

test-js: js/lib/rust_c_js.js
	node js/index.js

.PHONY: all clean test test-c test-js
