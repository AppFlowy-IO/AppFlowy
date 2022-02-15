use super::event_template::*;
use crate::code_gen::flowy_toml::{parse_crate_config_from, CrateConfig};
use crate::code_gen::util::{is_crate_dir, is_hidden, read_file, save_content_to_file_with_diff_prompt};
use flowy_ast::{event_ast::*, *};
use syn::Item;
use walkdir::WalkDir;

pub struct DartEventCodeGen();

impl DartEventCodeGen {
    pub fn gen(crate_name: &str, crate_path: &str) {
        let event_crates = parse_dart_event_files(vec![crate_path.to_owned()]);
        let event_ast = event_crates.iter().map(parse_event_crate).flatten().collect::<Vec<_>>();

        let event_render_ctx = ast_to_event_render_ctx(event_ast.as_ref());
        let mut render_result = String::new();
        for (index, render_ctx) in event_render_ctx.into_iter().enumerate() {
            let mut event_template = EventTemplate::new();

            if let Some(content) = event_template.render(render_ctx, index) {
                render_result.push_str(content.as_ref())
            }
        }

        save_content_to_file_with_diff_prompt(render_result.as_ref(), ".");
    }
}

pub struct DartEventCrate {
    crate_path: String,
    #[allow(dead_code)]
    crate_name: String,
    event_files: Vec<String>,
}

impl DartEventCrate {
    pub fn from_config(config: &CrateConfig) -> Self {
        DartEventCrate {
            crate_path: config.crate_path.clone(),
            crate_name: config.folder_name.clone(),
            event_files: config.flowy_config.event_files.clone(),
        }
    }
}

pub fn parse_dart_event_files(crate_paths: Vec<String>) -> Vec<DartEventCrate> {
    let mut dart_event_crates: Vec<DartEventCrate> = vec![];
    crate_paths.iter().for_each(|root| {
        let crates = WalkDir::new(root)
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
        .map(|event_file| {
            let file_path = format!("{}/{}", event_crate.crate_path, event_file);
            let file_content = read_file(file_path.as_ref()).unwrap();
            let ast = syn::parse_file(file_content.as_ref()).expect("Unable to parse file");
            ast.items
                .iter()
                .map(|item| match item {
                    Item::Enum(item_enum) => {
                        let ctxt = Ctxt::new();
                        let attrs =
                            flowy_ast::enum_from_ast(&ctxt, &item_enum.ident, &item_enum.variants, &item_enum.attrs);
                        ctxt.check().unwrap();
                        attrs
                            .iter()
                            .filter(|attr| !attr.attrs.event_attrs.ignore)
                            .enumerate()
                            .map(|(_index, attr)| EventASTContext::from(&attr.attrs))
                            .collect::<Vec<_>>()
                    }
                    _ => vec![],
                })
                .flatten()
                .collect::<Vec<_>>()
        })
        .flatten()
        .collect::<Vec<EventASTContext>>()
}

pub fn ast_to_event_render_ctx(ast: &[EventASTContext]) -> Vec<EventRenderContext> {
    ast.iter()
        .map(|event_ast| {
            let input_deserializer = event_ast
                .event_input
                .as_ref()
                .map(|event_input| event_input.get_ident().unwrap().to_string());

            let output_deserializer = event_ast
                .event_output
                .as_ref()
                .map(|event_output| event_output.get_ident().unwrap().to_string());
            // eprintln!(
            //     "😁 {:?} / {:?}",
            //     event_ast.event_input, event_ast.event_output
            // );

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
