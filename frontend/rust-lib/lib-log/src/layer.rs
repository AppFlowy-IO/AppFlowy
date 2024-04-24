use chrono::Local;
use std::{fmt, io::Write};

use serde::ser::{SerializeMap, Serializer};
use serde_json::Value;
use tracing::{Event, Id, Subscriber};
use tracing_bunyan_formatter::JsonStorage;
use tracing_core::metadata::Level;
use tracing_core::span::Attributes;
use tracing_subscriber::{fmt::MakeWriter, layer::Context, registry::SpanRef, Layer};

const LEVEL: &str = "level";
const TIME: &str = "time";
const MESSAGE: &str = "msg";

const LOG_MODULE_PATH: &str = "log.module_path";
const LOG_TARGET_PATH: &str = "log.target";

const RESERVED_FIELDS: [&str; 3] = [LEVEL, TIME, MESSAGE];
const IGNORE_FIELDS: [&str; 2] = [LOG_MODULE_PATH, LOG_TARGET_PATH];

pub struct FlowyFormattingLayer<'a, W: MakeWriter<'static> + 'static> {
  make_writer: W,
  with_target: bool,
  phantom: std::marker::PhantomData<&'a ()>,
}

impl<'a, W> FlowyFormattingLayer<'a, W>
where
  W: for<'writer> MakeWriter<'writer> + 'static,
{
  #[allow(dead_code)]
  pub fn new(make_writer: W) -> Self {
    Self {
      make_writer,
      with_target: true,
      phantom: std::marker::PhantomData,
    }
  }

  fn serialize_fields(
    &self,
    map_serializer: &mut impl SerializeMap<Error = serde_json::Error>,
    message: &str,
    _level: &Level,
  ) -> Result<(), std::io::Error> {
    map_serializer.serialize_entry(MESSAGE, &message)?;
    // map_serializer.serialize_entry(LEVEL, &format!("{}", level))?;
    map_serializer.serialize_entry(TIME, &Local::now().format("%Y-%m-%d %H:%M:%S").to_string())?;
    Ok(())
  }

  fn serialize_span<S: Subscriber + for<'b> tracing_subscriber::registry::LookupSpan<'b>>(
    &self,
    span: &SpanRef<'a, S>,
    ty: Type,
    ctx: &Context<'_, S>,
  ) -> Result<Vec<u8>, std::io::Error> {
    let mut buffer = Vec::new();
    let mut serializer = serde_json::Serializer::new(&mut buffer);
    let mut map_serializer = serializer.serialize_map(None)?;
    let message = format_span_context(span, ty, ctx);
    self.serialize_fields(&mut map_serializer, &message, span.metadata().level())?;
    if self.with_target {
      map_serializer.serialize_entry("target", &span.metadata().target())?;
    }

    // map_serializer.serialize_entry("line", &span.metadata().line())?;
    // map_serializer.serialize_entry("file", &span.metadata().file())?;

    let extensions = span.extensions();
    if let Some(visitor) = extensions.get::<JsonStorage>() {
      for (key, value) in visitor.values() {
        if !RESERVED_FIELDS.contains(key) && !IGNORE_FIELDS.contains(key) {
          map_serializer.serialize_entry(key, value)?;
        } else {
          tracing::debug!(
            "{} is a reserved field in the bunyan log format. Skipping it.",
            key
          );
        }
      }
    }
    map_serializer.end()?;
    Ok(buffer)
  }

  fn emit(&self, mut buffer: Vec<u8>) -> Result<(), std::io::Error> {
    buffer.write_all(b"\n")?;
    self.make_writer.make_writer().write_all(&buffer)
  }
}

/// The type of record we are dealing with: entering a span, exiting a span, an
/// event.
#[allow(dead_code)]
#[derive(Clone, Debug)]
pub enum Type {
  EnterSpan,
  ExitSpan,
  Event,
}

impl fmt::Display for Type {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    let repr = match self {
      Type::EnterSpan => "START",
      Type::ExitSpan => "END",
      Type::Event => "EVENT",
    };
    write!(f, "{}", repr)
  }
}

fn format_span_context<'b, S: Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>>(
  span: &SpanRef<'b, S>,
  ty: Type,
  _: &Context<'_, S>,
) -> String {
  if matches!(ty, Type::EnterSpan) {
    format!("[🟢 {} - {}]", span.metadata().name().to_uppercase(), ty)
  } else {
    format!("[{} - {}]", span.metadata().name().to_uppercase(), ty)
  }
}

fn format_event_message<S: Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>>(
  current_span: &Option<SpanRef<S>>,
  event: &Event,
  event_visitor: &JsonStorage<'_>,
  context: &Context<'_, S>,
) -> String {
  // Extract the "message" field, if provided. Fallback to the target, if missing.
  let mut message = event_visitor
    .values()
    .get("message")
    .and_then(|v| match v {
      Value::String(s) => Some(s.as_str()),
      _ => None,
    })
    .unwrap_or_else(|| event.metadata().target())
    .to_owned();

  // If the event is in the context of a span, prepend the span name to the
  // message.
  if let Some(span) = &current_span {
    message = format!(
      "{} {}",
      format_span_context(span, Type::Event, context),
      message
    );
  }

  message
}

impl<S, W> Layer<S> for FlowyFormattingLayer<'static, W>
where
  S: Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>,
  W: for<'writer> MakeWriter<'writer> + 'static,
{
  fn on_event(&self, event: &Event<'_>, ctx: Context<'_, S>) {
    // Events do not necessarily happen in the context of a span, hence
    // lookup_current returns an `Option<SpanRef<_>>` instead of a
    // `SpanRef<_>`.
    let current_span = ctx.lookup_current();

    let mut event_visitor = JsonStorage::default();
    event.record(&mut event_visitor);

    // Opting for a closure to use the ? operator and get more linear code.
    let format = || {
      let mut buffer = Vec::new();

      let mut serializer = serde_json::Serializer::new(&mut buffer);
      let mut map_serializer = serializer.serialize_map(None)?;

      let message = format_event_message(&current_span, event, &event_visitor, &ctx);
      self.serialize_fields(&mut map_serializer, &message, event.metadata().level())?;
      // Additional metadata useful for debugging
      // They should be nested under `src` (see https://github.com/trentm/node-bunyan#src )
      // but `tracing` does not support nested values yet

      if self.with_target {
        map_serializer.serialize_entry("target", event.metadata().target())?;
      }

      // map_serializer.serialize_entry("line", &event.metadata().line())?;
      // map_serializer.serialize_entry("file", &event.metadata().file())?;

      // Add all the other fields associated with the event, expect the message we
      // already used.
      for (key, value) in event_visitor.values().iter().filter(|(&key, _)| {
        key != "message" && !RESERVED_FIELDS.contains(&key) && !IGNORE_FIELDS.contains(&key)
      }) {
        map_serializer.serialize_entry(key, value)?;
      }

      // Add all the fields from the current span, if we have one.
      if let Some(span) = &current_span {
        let extensions = span.extensions();
        if let Some(visitor) = extensions.get::<JsonStorage>() {
          for (key, value) in visitor.values() {
            if !RESERVED_FIELDS.contains(key) && !IGNORE_FIELDS.contains(key) {
              map_serializer.serialize_entry(key, value)?;
            } else {
              tracing::debug!(
                "{} is a reserved field in the flowy log format. Skipping it.",
                key
              );
            }
          }
        }
      }
      map_serializer.end()?;
      Ok(buffer)
    };

    let result: std::io::Result<Vec<u8>> = format();
    if let Ok(formatted) = result {
      let _ = self.emit(formatted);
    }
  }

  fn on_new_span(&self, _attrs: &Attributes, id: &Id, ctx: Context<'_, S>) {
    let span = ctx.span(id).expect("Span not found, this is a bug");
    if let Ok(serialized) = self.serialize_span(&span, Type::EnterSpan, &ctx) {
      let _ = self.emit(serialized);
    }
  }

  fn on_close(&self, id: Id, ctx: Context<'_, S>) {
    let span = ctx.span(&id).expect("Span not found, this is a bug");
    if let Ok(serialized) = self.serialize_span(&span, Type::ExitSpan, &ctx) {
      let _ = self.emit(serialized);
    }
  }
}
