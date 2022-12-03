use flowy_ast::{ASTContainer, ASTResult};
use proc_macro2::TokenStream;

pub fn expand_derive(input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
    let ast_result = ASTResult::new();
    // let cont = match ASTContainer::from_ast(&ast_result, input) {
    //     Some(cont) => cont,
    //     None => return Err(ast_result.check().unwrap_err()),
    // };

    let mut token_stream: TokenStream = TokenStream::default();
    ast_result.check()?;
    Ok(token_stream)
}
