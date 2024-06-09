use crate::util::get_tera;
use tera::Context;

pub struct EventTemplate {
  tera_context: Context,
}

pub struct EventRenderContext {
  pub input_deserializer: Option<String>,
  pub output_deserializer: Option<String>,
  pub error_deserializer: String,
  pub event: String,
  pub event_ty: String,
  pub prefix: String,
}

#[allow(dead_code)]
impl EventTemplate {
  pub fn new() -> Self {
    EventTemplate {
      tera_context: Context::new(),
    }
  }

  pub fn render(&mut self, ctx: EventRenderContext, index: usize) -> Option<String> {
    self.tera_context.insert("index", &index);
    let event_func_name = format!("{}{}", ctx.event_ty, ctx.event);
    self
      .tera_context
      .insert("event_func_name", &event_func_name);
    self
      .tera_context
      .insert("event_name", &format!("{}.{}", ctx.prefix, ctx.event_ty));
    self.tera_context.insert("event", &ctx.event);

    self
      .tera_context
      .insert("has_input", &ctx.input_deserializer.is_some());
    match ctx.input_deserializer {
      None => {},
      Some(ref input) => self
        .tera_context
        .insert("input_deserializer", &format!("{}.{}", ctx.prefix, input)),
    }

    let has_output = ctx.output_deserializer.is_some();
    self.tera_context.insert("has_output", &has_output);

    match ctx.output_deserializer {
      None => self.tera_context.insert("output_deserializer", "void"),
      Some(ref output) => self
        .tera_context
        .insert("output_deserializer", &format!("{}.{}", ctx.prefix, output)),
    }

    self.tera_context.insert(
      "error_deserializer",
      &format!("{}.{}", ctx.prefix, ctx.error_deserializer),
    );

    let tera = get_tera("ts_event");
    match tera.render("event_template.tera", &self.tera_context) {
      Ok(r) => Some(r),
      Err(e) => {
        log::error!("{:?}", e);
        None
      },
    }
  }
}
