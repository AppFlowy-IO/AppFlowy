#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_imports)]
use crate::util::*;
use std::fs::OpenOptions;
use std::io::Write;
use walkdir::WalkDir;

pub struct CrateProtoInfo {
    pub files: Vec<ProtoFile>,
    pub inner: ProtobufCrate,
}

impl CrateProtoInfo {
    pub fn from_crate_info(inner: ProtobufCrate, files: Vec<ProtoFile>) -> Self {
        Self { files, inner }
    }

    pub fn create_crate_mod_file(&self) {
        // mod model;
        // pub use model::*;
        let mod_file_path = format!("{}/rev_sqlite", self.inner.protobuf_crate_name());
        let mut content = "#![cfg_attr(rustfmt, rustfmt::skip)]\n".to_owned();
        content.push_str("// Auto-generated, do not edit\n");
        content.push_str("mod model;\npub use model::*;");
        match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&mod_file_path)
        {
            Ok(ref mut file) => {
                file.write_all(content.as_bytes()).unwrap();
            }
            Err(err) => {
                panic!("Failed to open protobuf mod file: {}", err);
            }
        }
    }

    pub fn flutter_mod_dir(&self, root: &str) -> String {
        let crate_module_dir = format!("{}/{}", root, self.inner.folder_name);
        crate_module_dir
    }

    pub fn flutter_mod_file(&self, root: &str) -> String {
        let crate_module_dir = format!("{}/{}/protobuf.dart", root, self.inner.folder_name);
        crate_module_dir
    }
}

#[derive(Clone, Debug)]
pub struct ProtobufCrate {
    pub folder_name: String,
    pub proto_paths: Vec<String>,
    pub crate_path: String,
}

impl ProtobufCrate {
    pub fn from_config(config: CrateConfig) -> Self {
        let proto_paths = config.proto_paths();
        ProtobufCrate {
            folder_name: config.folder_name,
            proto_paths,
            crate_path: config.crate_path,
        }
    }

    fn protobuf_crate_name(&self) -> String {
        format!("{}/src/protobuf", self.crate_path)
    }

    pub fn proto_file_output_dir(&self) -> String {
        let dir = format!("{}/proto", self.protobuf_crate_name());
        create_dir_if_not_exist(dir.as_ref());
        dir
    }

    pub fn proto_struct_output_dir(&self) -> String {
        let dir = format!("{}/model", self.protobuf_crate_name());
        create_dir_if_not_exist(dir.as_ref());
        dir
    }

    pub fn proto_model_mod_file(&self) -> String {
        format!("{}/rev_sqlite", self.proto_struct_output_dir())
    }
}

#[derive(Debug)]
pub struct ProtoFile {
    pub file_path: String,
    pub file_name: String,
    pub structs: Vec<String>,
    pub enums: Vec<String>,
    pub generated_content: String,
}

pub fn parse_crate_info_from_path(roots: Vec<String>) -> Vec<ProtobufCrate> {
    let mut protobuf_crates: Vec<ProtobufCrate> = vec![];
    roots.iter().for_each(|root| {
        let crates = WalkDir::new(root)
            .into_iter()
            .filter_entry(|e| !is_hidden(e))
            .filter_map(|e| e.ok())
            .filter(|e| is_crate_dir(e))
            .flat_map(|e| parse_crate_config_from(&e))
            .map(ProtobufCrate::from_config)
            .collect::<Vec<ProtobufCrate>>();
        protobuf_crates.extend(crates);
    });
    protobuf_crates
}

pub struct FlutterProtobufInfo {
    package_path: String,
}
impl FlutterProtobufInfo {
    pub fn new(root: &str) -> Self {
        FlutterProtobufInfo {
            package_path: root.to_owned(),
        }
    }

    pub fn model_dir(&self) -> String {
        let model_dir = format!("{}/protobuf", self.package_path);
        create_dir_if_not_exist(model_dir.as_ref());
        model_dir
    }

    #[allow(dead_code)]
    pub fn mod_file_path(&self) -> String {
        let mod_file_path = format!("{}/protobuf.dart", self.package_path);
        mod_file_path
    }
}
