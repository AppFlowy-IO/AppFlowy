use tera::Context;

pub struct EventTemplate {
    tera_context: Context,
}

pub const DART_IMPORTED: &'static str = r#"
/// Auto gen code from rust ast, do not edit
part of 'cqrs.dart';
"#;

pub struct EventRenderContext {
    pub input_deserializer: String,
    pub output_deserializer: String,
    pub event: String,
    pub event_ty: String,
}

#[allow(dead_code)]
impl EventTemplate {
    pub fn new() -> Self {
        return EventTemplate {
            tera_context: Context::new(),
        };
    }

    pub fn render(&mut self, _render_context: EventRenderContext, _index: usize) -> Option<String> {
        None
        // if index == 0 {
        //     self.tera_context
        //         .insert("imported_dart_files", DART_IMPORTED)
        // }
        // self.tera_context.insert("index", &index);
        //
        //
        //
        // self.tera_context.insert(
        //     "command_request_struct_ident",
        //     &render_context.command_request_struct_ident,
        // );
        //
        // self.tera_context
        //     .insert("request_deserializer", &render_context.request_deserializer);
        //
        // if render_context.request_deserializer.is_empty() {
        //     self.tera_context.insert("has_request_deserializer", &false);
        // } else {
        //     self.tera_context.insert("has_request_deserializer", &true);
        // }
        // self.tera_context
        //     .insert("command_ident", &render_context.event);
        //
        // if render_context.response_deserializer.is_empty() {
        //     self.tera_context
        //         .insert("has_response_deserializer", &false);
        //     self.tera_context
        //         .insert("response_deserializer", "ResponsePacket");
        // } else {
        //     self.tera_context.insert("has_response_deserializer", &true);
        //     self.tera_context.insert(
        //         "response_deserializer",
        //         &render_context.response_deserializer,
        //     );
        // }
        //
        // self.tera_context
        //     .insert("async_cqrs_type", &render_context.async_cqrs_type);
        // let repo_absolute_path =
        //     std::fs::canonicalize("./flowy-scripts/rust-tool/src/flutter/cqrs")
        //         .unwrap()
        //         .as_path()
        //         .display()
        //         .to_string();
        //
        // let template_path = format!("{}/**/*.tera", repo_absolute_path);
        // let tera = match Tera::new(&template_path) {
        //     Ok(t) => t,
        //     Err(e) => {
        //         log::error!("Parsing error(s): {}", e);
        //         ::std::process::exit(1);
        //     }
        // };
        //
        // match tera.render("command_request_template.tera", &self.tera_context) {
        //     Ok(r) => Some(r),
        //     Err(e) => {
        //         log::error!("{:?}", e);
        //         None
        //     }
        // }
    }
}
