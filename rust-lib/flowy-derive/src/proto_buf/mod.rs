mod deserialize;
mod enum_serde;
mod serialize;
mod util;

use crate::proto_buf::{
    deserialize::make_de_token_steam,
    enum_serde::make_enum_token_stream,
    serialize::make_se_token_stream,
};
use flowy_ast::*;
use proc_macro2::TokenStream;

pub fn expand_derive(input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
    let ctxt = Ctxt::new();
    let cont = match ASTContainer::from_ast(&ctxt, input) {
        Some(cont) => cont,
        None => return Err(ctxt.check().unwrap_err()),
    };

    let mut token_stream: TokenStream = TokenStream::default();

    let de_token_stream = make_de_token_steam(&ctxt, &cont);
    if de_token_stream.is_some() {
        token_stream.extend(de_token_stream.unwrap());
    }

    let se_token_stream = make_se_token_stream(&ctxt, &cont);
    if se_token_stream.is_some() {
        token_stream.extend(se_token_stream.unwrap());
    }

    ctxt.check()?;
    Ok(token_stream)
}

pub fn expand_enum_derive(input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
    let ctxt = Ctxt::new();
    let cont = match ASTContainer::from_ast(&ctxt, input) {
        Some(cont) => cont,
        None => return Err(ctxt.check().unwrap_err()),
    };

    let mut token_stream: TokenStream = TokenStream::default();

    let enum_token_stream = make_enum_token_stream(&ctxt, &cont);
    if enum_token_stream.is_some() {
        token_stream.extend(enum_token_stream.unwrap());
    }

    ctxt.check()?;
    Ok(token_stream)
}
