use proc_macro2::TokenStream;

// #[proc_macro_derive(DartEvent, attributes(event_ty))]
pub fn expand_enum_derive(_input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
    Ok(TokenStream::default())
}
