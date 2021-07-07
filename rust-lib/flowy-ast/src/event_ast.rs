use crate::ASTEnumAttrVariant;

pub struct EventASTContext {
    pub event: syn::Ident,
    pub event_ty: syn::Ident,
    pub event_request_struct: syn::Ident,
    pub event_input: Option<syn::Path>,
    pub event_output: Option<syn::Path>,
}

impl EventASTContext {
    pub fn from(variant: &ASTEnumAttrVariant) -> EventASTContext {
        let command_name = variant.name.clone();
        if command_name.is_empty() {
            panic!("Invalid command name: {}", variant.name);
        }

        let event = format_ident!("{}", &command_name);
        let splits = command_name.split("_").collect::<Vec<&str>>();

        let event_ty = format_ident!("UserEvent");
        let event_request_struct = format_ident!("{}Event", &splits.join(""));

        let event_input = variant.event_input();
        let event_output = variant.event_output();

        EventASTContext {
            event,
            event_ty,
            event_request_struct,
            event_input,
            event_output,
        }
    }
}
