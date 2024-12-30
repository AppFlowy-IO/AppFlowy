mod event_template;

use crate::ast::EventASTContext;
use crate::flowy_toml::{parse_crate_config_from, CrateConfig};
use crate::ts_event::event_template::{EventRenderContext, EventTemplate};
use crate::util::{is_crate_dir, is_hidden, path_string_with_component, read_file};
use crate::Project;
use flowy_ast::ASTResult;
use std::collections::HashSet;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use syn::Item;
use walkdir::WalkDir;

pub fn gen(dest_folder_name: &str, project: Project) {
  let root = project.event_root();
  let backend_service_path = project.dst();

  let crate_path = std::fs::canonicalize(".")
    .unwrap()
    .as_path()
    .display()
    .to_string();
  let event_crates = parse_ts_event_files(vec![crate_path]);
  let event_ast = event_crates
    .iter()
    .flat_map(parse_event_crate)
    .collect::<Vec<_>>();

  let event_render_ctx = ast_to_event_render_ctx(event_ast.as_ref());
  let mut render_result = project.event_imports();

  for (index, render_ctx) in event_render_ctx.into_iter().enumerate() {
    let mut event_template = EventTemplate::new();

    if let Some(content) = event_template.render(render_ctx, index) {
      render_result.push_str(content.as_ref())
    }
  }
  render_result.push_str(TS_FOOTER);

  let ts_event_folder: PathBuf = [&root, &backend_service_path, "events", dest_folder_name]
    .iter()
    .collect();
  if !ts_event_folder.as_path().exists() {
    std::fs::create_dir_all(ts_event_folder.as_path()).unwrap();
  }

  let event_file = "event";
  let event_file_ext = "ts";
  let ts_event_file_path = path_string_with_component(
    &ts_event_folder,
    vec![&format!("{}.{}", event_file, event_file_ext)],
  );
  println!("cargo:rerun-if-changed={}", ts_event_file_path);

  match std::fs::OpenOptions::new()
    .create(true)
    .write(true)
    .append(false)
    .truncate(true)
    .open(&ts_event_file_path)
  {
    Ok(ref mut file) => {
      file.write_all(render_result.as_bytes()).unwrap();
      File::flush(file).unwrap();
    },
    Err(err) => {
      panic!("Failed to open file: {}, {:?}", ts_event_file_path, err);
    },
  }

  let ts_index = path_string_with_component(&ts_event_folder, vec!["index.ts"]);
  match std::fs::OpenOptions::new()
    .create(true)
    .write(true)
    .append(false)
    .truncate(true)
    .open(ts_index)
  {
    Ok(ref mut file) => {
      let mut export = String::new();
      export.push_str("// Auto-generated, do not edit \n");
      export.push_str(&format!(
        "export * from '../../models/{}';\n",
        dest_folder_name
      ));
      export.push_str(&format!("export * from './{}';\n", event_file));
      file.write_all(export.as_bytes()).unwrap();
      File::flush(file).unwrap();
    },
    Err(err) => {
      panic!("Failed to open file: {}", err);
    },
  }
}

#[derive(Debug)]
pub struct TsEventCrate {
  crate_path: PathBuf,
  event_files: Vec<String>,
}

impl TsEventCrate {
  pub fn from_config(config: &CrateConfig) -> Self {
    TsEventCrate {
      crate_path: config.crate_path.clone(),
      event_files: config.flowy_config.event_files.clone(),
    }
  }
}

pub fn parse_ts_event_files(crate_paths: Vec<String>) -> Vec<TsEventCrate> {
  let mut ts_event_crates: Vec<TsEventCrate> = vec![];
  crate_paths.iter().for_each(|path| {
    let crates = WalkDir::new(path)
      .into_iter()
      .filter_entry(|e| !is_hidden(e))
      .filter_map(|e| e.ok())
      .filter(is_crate_dir)
      .flat_map(|e| parse_crate_config_from(&e))
      .map(|crate_config| TsEventCrate::from_config(&crate_config))
      .collect::<Vec<TsEventCrate>>();
    ts_event_crates.extend(crates);
  });
  ts_event_crates
}

pub fn parse_event_crate(event_crate: &TsEventCrate) -> Vec<EventASTContext> {
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
  let mut import_objects = HashSet::new();
  ast.iter().for_each(|event_ast| {
    if let Some(input) = event_ast.event_input.as_ref() {
      import_objects.insert(input.get_ident().unwrap().to_string());
    }
    if let Some(output) = event_ast.event_output.as_ref() {
      import_objects.insert(output.get_ident().unwrap().to_string());
    }
  });

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
        error_deserializer: event_ast.event_error.to_string(),
        event: event_ast.event.to_string(),
        event_ty: event_ast.event_ty.to_string(),
        prefix: "pb".to_string(),
      }
    })
    .collect::<Vec<EventRenderContext>>()
}

const TS_FOOTER: &str = r#"
"#;
