#![feature(proc_macro, wasm_custom_section, wasm_import_module)]

#[macro_use]
extern crate cfg_if;

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
            return c_input.to_str().unwrap().to_owned();
        }

        fn to_out_str(output: String) -> OutStr {
            return CString::new(output).unwrap().into_raw();
        }

        fn log(str: &str) {
            println!("{}", str);
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

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
extern {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

#[cfg(not(target_arch = "wasm32"))]
#[no_mangle]
pub extern "C" fn greet(name: InStr) -> OutStr {
    to_out_str(do_greet(from_in_str(name)))
}

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub fn greet(name: InStr) -> OutStr {
    to_out_str(do_greet(from_in_str(name)))
}

fn do_greet(name: String) -> String {
    log(&format!("Hello, {}!", name));
    String::from("Bye!")
}
