#![allow(dead_code)]
use crate::code_gen::flowy_toml::{parse_crate_config_from, CrateConfig, FlowyConfig};
use crate::code_gen::util::*;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;
use std::str::FromStr;
use walkdir::WalkDir;

#[derive(Debug)]
pub struct ProtobufCrateContext {
    pub files: Vec<ProtoFile>,
    pub protobuf_crate: ProtobufCrate,
}

impl ProtobufCrateContext {
    pub fn from_crate_info(inner: ProtobufCrate, files: Vec<ProtoFile>) -> Self {
        Self {
            files,
            protobuf_crate: inner,
        }
    }

    pub fn create_crate_mod_file(&self) {
        // mod model;
        // pub use model::*;
        let mod_file_path = path_string_with_component(&self.protobuf_crate.protobuf_crate_name(), vec!["mod.rs"]);
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

    #[allow(dead_code)]
    pub fn flutter_mod_dir(&self, root: &str) -> String {
        let crate_module_dir = format!("{}/{}", root, self.protobuf_crate.folder_name);
        crate_module_dir
    }

    #[allow(dead_code)]
    pub fn flutter_mod_file(&self, root: &str) -> String {
        let crate_module_dir = format!("{}/{}/protobuf.dart", root, self.protobuf_crate.folder_name);
        crate_module_dir
    }
}

#[derive(Clone, Debug)]
pub struct ProtobufCrate {
    pub folder_name: String,
    pub proto_paths: Vec<PathBuf>,
    pub crate_path: PathBuf,
    pub flowy_config: FlowyConfig,
}

impl ProtobufCrate {
    pub fn from_config(config: CrateConfig) -> Self {
        let proto_paths = config.proto_paths();

        ProtobufCrate {
            folder_name: config.folder_name,
            proto_paths,
            crate_path: config.crate_path,
            flowy_config: config.flowy_config.clone(),
        }
    }

    fn protobuf_crate_name(&self) -> PathBuf {
        let crate_path = PathBuf::from(&self.flowy_config.protobuf_crate_path);
        crate_path
    }

    pub fn proto_output_dir(&self) -> PathBuf {
        let output_dir = PathBuf::from(&self.flowy_config.proto_output_dir);
        create_dir_if_not_exist(&output_dir);
        output_dir
    }

    pub fn create_output_dir(&self) -> PathBuf {
        let path = self.protobuf_crate_name();
        let dir = path_buf_with_component(&path, vec!["model"]);
        create_dir_if_not_exist(&dir);
        dir
    }

    pub fn proto_model_mod_file(&self) -> String {
        path_string_with_component(&self.create_output_dir(), vec!["mod.rs"])
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
            .filter(is_crate_dir)
            .flat_map(|e| parse_crate_config_from(&e))
            .map(ProtobufCrate::from_config)
            .collect::<Vec<ProtobufCrate>>();
        protobuf_crates.extend(crates);
    });
    protobuf_crates
}
