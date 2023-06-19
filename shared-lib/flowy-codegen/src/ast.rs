use flowy_ast::EventEnumAttrs;
use quote::format_ident;

#[allow(dead_code)]
pub struct EventASTContext {
  pub event: syn::Ident,
  pub event_ty: syn::Ident,
  pub event_request_struct: syn::Ident,
  pub event_input: Option<syn::Path>,
  pub event_output: Option<syn::Path>,
  pub event_error: String,
}

impl EventASTContext {
  #[allow(dead_code)]
  pub fn from(enum_attrs: &EventEnumAttrs) -> EventASTContext {
    let command_name = enum_attrs.enum_item_name.clone();
    if command_name.is_empty() {
      panic!("Invalid command name: {}", enum_attrs.enum_item_name);
    }

    let event = format_ident!("{}", &command_name);
    let splits = command_name.split('_').collect::<Vec<&str>>();

    let event_ty = format_ident!("{}", enum_attrs.enum_name);
    let event_request_struct = format_ident!("{}Event", &splits.join(""));

    let event_input = enum_attrs.event_input();
    let event_output = enum_attrs.event_output();
    let event_error = enum_attrs.event_error();

    EventASTContext {
      event,
      event_ty,
      event_request_struct,
      event_input,
      event_output,
      event_error,
    }
  }
}
