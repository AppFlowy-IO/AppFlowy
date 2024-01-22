#![allow(unused_attributes)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_results)]
use crate::protobuf_file::ast::parse_protobuf_context_from;
use crate::protobuf_file::proto_info::ProtobufCrateContext;
use crate::protobuf_file::ProtoFile;
use crate::util::*;
use crate::ProtoCache;
use std::collections::HashMap;
use std::fs::File;
use std::path::Path;
use std::{fs::OpenOptions, io::Write};

pub struct ProtoGenerator();
impl ProtoGenerator {
  pub fn gen(crate_name: &str, crate_path: &str) -> Vec<ProtobufCrateContext> {
    let crate_contexts = parse_protobuf_context_from(vec![crate_path.to_owned()]);
    write_proto_files(&crate_contexts);
    write_rust_crate_mod_file(&crate_contexts);

    let proto_cache = ProtoCache::from_crate_contexts(&crate_contexts);
    let proto_cache_str = serde_json::to_string(&proto_cache).unwrap();

    let crate_cache_dir = path_buf_with_component(&cache_dir(), vec![crate_name]);
    if !crate_cache_dir.as_path().exists() {
      std::fs::create_dir_all(&crate_cache_dir).unwrap();
    }

    let protobuf_cache_path = path_string_with_component(&crate_cache_dir, vec!["proto_cache"]);

    match std::fs::OpenOptions::new()
      .create(true)
      .write(true)
      .append(false)
      .truncate(true)
      .open(&protobuf_cache_path)
    {
      Ok(ref mut file) => {
        file.write_all(proto_cache_str.as_bytes()).unwrap();
        File::flush(file).unwrap();
      },
      Err(_err) => {
        panic!("Failed to open file: {}", protobuf_cache_path);
      },
    }

    crate_contexts
  }
}

fn write_proto_files(crate_contexts: &[ProtobufCrateContext]) {
  let file_path_content_map = crate_contexts
    .iter()
    .flat_map(|ctx| {
      ctx
        .files
        .iter()
        .map(|file| {
          (
            file.file_path.clone(),
            ProtoFileSymbol {
              file_name: file.file_name.clone(),
              symbols: file.symbols(),
            },
          )
        })
        .collect::<HashMap<String, ProtoFileSymbol>>()
    })
    .collect::<HashMap<String, ProtoFileSymbol>>();

  for context in crate_contexts {
    let dir = context.protobuf_crate.proto_output_path();
    context.files.iter().for_each(|file| {
      // syntax
      let mut file_content = file.syntax.clone();

      // import
      file_content.push_str(&gen_import_content(file, &file_path_content_map));

      // content
      file_content.push_str(&file.content);

      let proto_file = format!("{}.proto", &file.file_name);
      let proto_file_path = path_string_with_component(&dir, vec![&proto_file]);
      save_content_to_file_with_diff_prompt(&file_content, proto_file_path.as_ref());
    });
  }
}

fn gen_import_content(
  current_file: &ProtoFile,
  file_path_symbols_map: &HashMap<String, ProtoFileSymbol>,
) -> String {
  let mut import_files: Vec<String> = vec![];
  file_path_symbols_map
    .iter()
    .for_each(|(file_path, proto_file_symbols)| {
      if file_path != &current_file.file_path {
        current_file.ref_types.iter().for_each(|ref_type| {
          if proto_file_symbols.symbols.contains(ref_type) {
            let import_file = format!("import \"{}.proto\";", proto_file_symbols.file_name);
            if !import_files.contains(&import_file) {
              import_files.push(import_file);
            }
          }
        });
      }
    });
  if import_files.len() == 1 {
    format!("{}\n", import_files.pop().unwrap())
  } else {
    import_files.join("\n")
  }
}

struct ProtoFileSymbol {
  file_name: String,
  symbols: Vec<String>,
}

fn write_rust_crate_mod_file(crate_contexts: &[ProtobufCrateContext]) {
  for context in crate_contexts {
    let mod_path = context.protobuf_crate.proto_model_mod_file();
    match OpenOptions::new()
      .create(true)
      .write(true)
      .append(false)
      .truncate(true)
      .open(&mod_path)
    {
      Ok(ref mut file) => {
        let mut mod_file_content = String::new();

        mod_file_content.push_str("#![cfg_attr(rustfmt, rustfmt::skip)]\n");
        mod_file_content.push_str(" #![allow(ambiguous_glob_reexports)]\n");

        mod_file_content.push_str("// Auto-generated, do not edit\n");
        walk_dir(
          context.protobuf_crate.proto_output_path(),
          |e| !e.file_type().is_dir() && !e.file_name().to_string_lossy().starts_with('.'),
          |_, name| {
            let c = format!("\nmod {};\npub use {}::*;\n", &name, &name);
            mod_file_content.push_str(c.as_ref());
          },
        );
        file.write_all(mod_file_content.as_bytes()).unwrap();
      },
      Err(err) => {
        panic!("Failed to open file: {}", err);
      },
    }
  }
}

impl ProtoCache {
  fn from_crate_contexts(crate_contexts: &[ProtobufCrateContext]) -> Self {
    let proto_files = crate_contexts
      .iter()
      .flat_map(|crate_info| &crate_info.files)
      .collect::<Vec<&ProtoFile>>();

    let structs: Vec<String> = proto_files
      .iter()
      .flat_map(|info| info.structs.clone())
      .collect();
    let enums: Vec<String> = proto_files
      .iter()
      .flat_map(|info| info.enums.clone())
      .collect();
    Self { structs, enums }
  }
}
