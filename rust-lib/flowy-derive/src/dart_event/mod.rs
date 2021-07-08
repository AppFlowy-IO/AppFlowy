use proc_macro2::TokenStream;
pub fn expand_enum_derive(_input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
    Ok(TokenStream::default())
}
