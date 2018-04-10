all: test

clean:
	rm -rf main rust_c_js.js rust_c_js_bg.js rust_c_js_bg.wasm rust/target

main: src/main.c rust/target/debug/librust_c_js.dylib
	gcc src/main.c -L rust/target/debug -lrust_c_js -o main

rust_c_js.js: rust/target/wasm32-unknown-unknown/debug/rust_c_js.wasm
	wasm-bindgen rust/target/wasm32-unknown-unknown/debug/rust_c_js.wasm --nodejs --out-dir .

rust/target/debug/librust_c_js.dylib: rust/Cargo.toml rust/src/lib.rs
	cd rust && cargo build

rust/target/wasm32-unknown-unknown/debug/rust_c_js.wasm: rust/Cargo.toml rust/src/lib.rs
	cd rust && cargo build --target wasm32-unknown-unknown

test: test-c test-js

test-c: main
	LD_LIBRARY_PATH=rust/target/debug ./main

test-js: rust_c_js.js
	node src/main.js

.PHONY: all clean test test-c test-js
