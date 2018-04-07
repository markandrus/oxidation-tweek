#![feature(proc_macro, wasm_custom_section, wasm_import_module)]

#[macro_use]
extern crate cfg_if;

cfg_if! {
    if #[cfg(target_arch = "wasm32")] {
        extern crate wasm_bindgen;
        use wasm_bindgen::prelude::*;

        #[wasm_bindgen]
        extern {
            #[wasm_bindgen(js_namespace = console)]
            fn log(s: &str);
        }

        #[wasm_bindgen]
        pub fn greet(name: &str) {
            do_greet(name);
        }
    } else {
        extern crate libc;
        use std::ffi::CStr;
        use libc::c_char;

        fn log(str: &str) {
            println!("{}", str);
        }

        #[no_mangle]
        pub extern "C" fn greet(name: *const c_char) {
            let c_name = unsafe { CStr::from_ptr(name) };
            do_greet(c_name.to_str().unwrap());
        }
    }
}

fn do_greet(name: &str) {
    log(&format!("Hello, {}!", name));
}
