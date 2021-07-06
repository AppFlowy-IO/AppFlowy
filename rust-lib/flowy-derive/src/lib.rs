// https://docs.rs/syn/1.0.48/syn/struct.DeriveInput.html
extern crate proc_macro;

use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, DeriveInput};

#[macro_use]
extern crate quote;

mod derive_cache;
mod proto_buf;

// Inspired by https://serde.rs/attributes.html
#[proc_macro_derive(ProtoBuf, attributes(pb))]
pub fn derive_proto_buf(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    proto_buf::expand_derive(&input)
        .unwrap_or_else(to_compile_errors)
        .into()
}

#[proc_macro_derive(ProtoBuf_Enum, attributes(pb))]
pub fn derive_proto_buf_enum(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    proto_buf::expand_enum_derive(&input)
        .unwrap_or_else(to_compile_errors)
        .into()
}

fn to_compile_errors(errors: Vec<syn::Error>) -> proc_macro2::TokenStream {
    let compile_errors = errors.iter().map(syn::Error::to_compile_error);
    quote!(#(#compile_errors)*)
}
