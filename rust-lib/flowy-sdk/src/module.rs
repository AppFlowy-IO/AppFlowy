use flowy_dispatch::prelude::Module;

pub fn build_modules() -> Vec<Module> { vec![flowy_user::module::create()] }
