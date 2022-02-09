mod derive_meta;
mod proto_file;

pub use derive_meta::*;
pub use proto_file::*;
use std::fs::File;
use std::io::Read;
use tera::Tera;

pub fn get_tera(directory: &str) -> Tera {
    let mut root = format!("{}/../shared-lib/lib-infra/src/", env!("CARGO_MAKE_WORKING_DIRECTORY"));
    root.push_str(directory);

    let root_absolute_path = std::fs::canonicalize(root).unwrap().as_path().display().to_string();
    let mut template_path = format!("{}/**/*.tera", root_absolute_path);
    if cfg!(windows) {
        // remove "\\?\" prefix on windows
        template_path = format!("{}/**/*.tera", &root_absolute_path[4..]);
    }

    match Tera::new(template_path.as_ref()) {
        Ok(t) => t,
        Err(e) => {
            log::error!("Parsing error(s): {}", e);
            ::std::process::exit(1);
        }
    }
}

pub fn read_file(path: &str) -> Option<String> {
    let mut file = File::open(path).unwrap_or_else(|_| panic!("Unable to open file at {}", path));
    let mut content = String::new();
    match file.read_to_string(&mut content) {
        Ok(_) => Some(content),
        Err(e) => {
            log::error!("{}, with error: {:?}", path, e);
            Some("".to_string())
        }
    }
}
