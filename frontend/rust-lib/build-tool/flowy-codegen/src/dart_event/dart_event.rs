use std::fs::File;
use std::io::Write;
use std::path::PathBuf;

use syn::Item;
use walkdir::WalkDir;

use flowy_ast::ASTResult;

use crate::ast::EventASTContext;
use crate::flowy_toml::{parse_crate_config_from, CrateConfig};
use crate::util::{is_crate_dir, is_hidden, path_string_with_component, read_file};

use super::event_template::*;

pub fn gen(crate_name: &str) {
  if std::env::var("CARGO_MAKE_WORKING_DIRECTORY").is_err() {
    println!("CARGO_MAKE_WORKING_DIRECTORY was not set, skip generate dart pb");
    return;
  }

  if std::env::var("FLUTTER_FLOWY_SDK_PATH").is_err() {
    println!("FLUTTER_FLOWY_SDK_PATH was not set, skip generate dart pb");
    return;
  }

  let crate_path = std::fs::canonicalize(".")
    .unwrap()
    .as_path()
    .display()
    .to_string();
  let event_crates = parse_dart_event_files(vec![crate_path]);
  let event_ast = event_crates
    .iter()
    .flat_map(parse_event_crate)
    .collect::<Vec<_>>();

  let event_render_ctx = ast_to_event_render_ctx(event_ast.as_ref());
  let mut render_result = DART_IMPORTED.to_owned();
  for (index, render_ctx) in event_render_ctx.into_iter().enumerate() {
    let mut event_template = EventTemplate::new();

    if let Some(content) = event_template.render(render_ctx, index) {
      render_result.push_str(content.as_ref())
    }
  }

  let dart_event_folder: PathBuf = [
    &std::env::var("CARGO_MAKE_WORKING_DIRECTORY").unwrap(),
    &std::env::var("FLUTTER_FLOWY_SDK_PATH").unwrap(),
    "lib",
    "dispatch",
    "dart_event",
    crate_name,
  ]
  .iter()
  .collect();

  if !dart_event_folder.as_path().exists() {
    std::fs::create_dir_all(dart_event_folder.as_path()).unwrap();
  }

  let dart_event_file_path =
    path_string_with_component(&dart_event_folder, vec!["dart_event.dart"]);
  println!("cargo:rerun-if-changed={}", dart_event_file_path);

  match std::fs::OpenOptions::new()
    .create(true)
    .write(true)
    .append(false)
    .truncate(true)
    .open(&dart_event_file_path)
  {
    Ok(ref mut file) => {
      file.write_all(render_result.as_bytes()).unwrap();
      File::flush(file).unwrap();
    },
    Err(err) => {
      panic!("Failed to open file: {}, {:?}", dart_event_file_path, err);
    },
  }
}

const DART_IMPORTED: &str = r#"
/// Auto generate. Do not edit
part of '../../dispatch.dart';
"#;

#[derive(Debug)]
pub struct DartEventCrate {
  crate_path: PathBuf,
  event_files: Vec<String>,
}

impl DartEventCrate {
  pub fn from_config(config: &CrateConfig) -> Self {
    DartEventCrate {
      crate_path: config.crate_path.clone(),
      event_files: config.flowy_config.event_files.clone(),
    }
  }
}

pub fn parse_dart_event_files(crate_paths: Vec<String>) -> Vec<DartEventCrate> {
  let mut dart_event_crates: Vec<DartEventCrate> = vec![];
  crate_paths.iter().for_each(|path| {
    let crates = WalkDir::new(path)
      .into_iter()
      .filter_entry(|e| !is_hidden(e))
      .filter_map(|e| e.ok())
      .filter(is_crate_dir)
      .flat_map(|e| parse_crate_config_from(&e))
      .map(|crate_config| DartEventCrate::from_config(&crate_config))
      .collect::<Vec<DartEventCrate>>();
    dart_event_crates.extend(crates);
  });
  dart_event_crates
}

pub fn parse_event_crate(event_crate: &DartEventCrate) -> Vec<EventASTContext> {
  event_crate
    .event_files
    .iter()
    .flat_map(|event_file| {
      let file_path =
        path_string_with_component(&event_crate.crate_path, vec![event_file.as_str()]);

      let file_content = read_file(file_path.as_ref()).unwrap();
      let ast = syn::parse_file(file_content.as_ref()).expect("Unable to parse file");
      ast
        .items
        .iter()
        .flat_map(|item| match item {
          Item::Enum(item_enum) => {
            let ast_result = ASTResult::new();
            let attrs = flowy_ast::enum_from_ast(
              &ast_result,
              &item_enum.ident,
              &item_enum.variants,
              &item_enum.attrs,
            );
            ast_result.check().unwrap();
            attrs
              .iter()
              .filter(|attr| !attr.attrs.event_attrs.ignore)
              .enumerate()
              .map(|(_index, variant)| EventASTContext::from(&variant.attrs))
              .collect::<Vec<_>>()
          },
          _ => vec![],
        })
        .collect::<Vec<_>>()
    })
    .collect::<Vec<EventASTContext>>()
}

pub fn ast_to_event_render_ctx(ast: &[EventASTContext]) -> Vec<EventRenderContext> {
  ast
    .iter()
    .map(|event_ast| {
      let input_deserializer = event_ast
        .event_input
        .as_ref()
        .map(|event_input| event_input.get_ident().unwrap().to_string());

      let output_deserializer = event_ast
        .event_output
        .as_ref()
        .map(|event_output| event_output.get_ident().unwrap().to_string());

      EventRenderContext {
        input_deserializer,
        output_deserializer,
        error_deserializer: event_ast.event_error.clone(),
        event: event_ast.event.to_string(),
        event_ty: event_ast.event_ty.to_string(),
      }
    })
    .collect::<Vec<EventRenderContext>>()
}
