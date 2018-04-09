#![feature(proc_macro, wasm_custom_section, wasm_import_module)]

#[cfg(target_arch = "wasm32")]
extern crate wasm_bindgen;
#[cfg(target_arch = "wasm32")]
use wasm_bindgen::prelude::*;

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
extern {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub fn greet(name: &str) {
    do_greet(name);
}

#[cfg(not(target_arch = "wasm32"))]
extern crate libc;
#[cfg(not(target_arch = "wasm32"))]
use std::ffi::CStr;
#[cfg(not(target_arch = "wasm32"))]
use libc::c_char;

#[cfg(not(target_arch = "wasm32"))]
fn log(str: &str) {
    println!("{}", str);
}

#[cfg(not(target_arch = "wasm32"))]
#[no_mangle]
pub extern "C" fn greet(name: *const c_char) {
    let c_name = unsafe { CStr::from_ptr(name) };
    do_greet(c_name.to_str().unwrap());
}

fn do_greet(name: &str) {
    log(&format!("Hello, {}!", name));
}
