use tera::Context;

pub struct EventTemplate {
    tera_context: Context,
}

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
    }
}
