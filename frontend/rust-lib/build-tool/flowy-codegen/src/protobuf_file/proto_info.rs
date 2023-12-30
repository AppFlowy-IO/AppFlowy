#![allow(dead_code)]
use crate::flowy_toml::{parse_crate_config_from, CrateConfig, FlowyConfig};
use crate::util::*;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::{Path, PathBuf};
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
    let mod_file_path =
      path_string_with_component(&self.protobuf_crate.protobuf_crate_path(), vec!["mod.rs"]);
    let mut content = "#![cfg_attr(rustfmt, rustfmt::skip)]\n".to_owned();
    content.push_str(" #![allow(ambiguous_glob_reexports)]\n");
    content.push_str("// Auto-generated, do not edit\n");
    content.push_str("mod model;\npub use model::*;");
    match OpenOptions::new()
      .create(true)
      .write(true)
      .append(false)
      .truncate(true)
      .open(Path::new(&mod_file_path))
    {
      Ok(ref mut file) => {
        file.write_all(content.as_bytes()).unwrap();
      },
      Err(err) => {
        panic!("Failed to open protobuf mod file: {}", err);
      },
    }
  }

  #[allow(dead_code)]
  pub fn flutter_mod_dir(&self, root: &str) -> String {
    let crate_module_dir = format!("{}/{}", root, self.protobuf_crate.crate_folder);
    crate_module_dir
  }

  #[allow(dead_code)]
  pub fn flutter_mod_file(&self, root: &str) -> String {
    let crate_module_dir = format!(
      "{}/{}/protobuf.dart",
      root, self.protobuf_crate.crate_folder
    );
    crate_module_dir
  }
}

#[derive(Clone, Debug)]
pub struct ProtobufCrate {
  pub crate_folder: String,
  pub crate_path: PathBuf,
  flowy_config: FlowyConfig,
}

impl ProtobufCrate {
  pub fn from_config(config: CrateConfig) -> Self {
    ProtobufCrate {
      crate_path: config.crate_path,
      crate_folder: config.crate_folder,
      flowy_config: config.flowy_config,
    }
  }

  // Return the file paths for each rust file that used to generate the proto file.
  pub fn proto_input_paths(&self) -> Vec<PathBuf> {
    self
      .flowy_config
      .proto_input
      .iter()
      .map(|name| path_buf_with_component(&self.crate_path, vec![name]))
      .collect::<Vec<PathBuf>>()
  }

  // The protobuf_crate_path is used to store the generated protobuf Rust structures.
  pub fn protobuf_crate_path(&self) -> PathBuf {
    let crate_path = PathBuf::from(&self.flowy_config.protobuf_crate_path);
    create_dir_if_not_exist(&crate_path);
    crate_path
  }

  // The proto_output_path is used to store the proto files
  pub fn proto_output_path(&self) -> PathBuf {
    let output_dir = PathBuf::from(&self.flowy_config.proto_output);
    create_dir_if_not_exist(&output_dir);
    output_dir
  }

  pub fn proto_model_mod_file(&self) -> String {
    path_string_with_component(&self.protobuf_crate_path(), vec!["mod.rs"])
  }
}

#[derive(Debug)]
pub struct ProtoFile {
  pub file_path: String,
  pub file_name: String,
  pub structs: Vec<String>,
  // store the type of current file using
  pub ref_types: Vec<String>,

  pub enums: Vec<String>,
  // proto syntax. "proto3" or "proto2"
  pub syntax: String,

  // proto message content
  pub content: String,
}

impl ProtoFile {
  pub fn symbols(&self) -> Vec<String> {
    let mut symbols = self.structs.clone();
    let mut enum_symbols = self.enums.clone();
    symbols.append(&mut enum_symbols);
    symbols
  }
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
