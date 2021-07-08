use crate::util::get_tera;
use tera::Context;

pub struct EventTemplate {
    tera_context: Context,
}

pub const DART_IMPORTED: &'static str = r#"
/// Auto gen code from rust ast, do not edit
part of 'dispatch.dart';
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

    pub fn render(&mut self, ctx: EventRenderContext, index: usize) -> Option<String> {
        if index == 0 {
            self.tera_context
                .insert("imported_dart_files", DART_IMPORTED)
        }
        self.tera_context.insert("index", &index);

        let dart_class_name = format!("{}{}", ctx.event_ty, ctx.event);
        let event = format!("{}.{}", ctx.event_ty, ctx.event);

        self.tera_context.insert("event_class", &dart_class_name);
        self.tera_context.insert("event", &event);
        self.tera_context
            .insert("input_deserializer", &ctx.input_deserializer);
        self.tera_context
            .insert("output_deserializer", &ctx.output_deserializer);

        let tera = get_tera("dart_event");
        match tera.render("event_template.tera", &self.tera_context) {
            Ok(r) => Some(r),
            Err(e) => {
                log::error!("{:?}", e);
                None
            }
        }
    }
}
