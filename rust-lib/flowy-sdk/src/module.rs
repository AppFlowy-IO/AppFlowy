use flowy_sys::prelude::Module;

pub fn build_modules() -> Vec<Module> { vec![flowy_user::module::create()] }
