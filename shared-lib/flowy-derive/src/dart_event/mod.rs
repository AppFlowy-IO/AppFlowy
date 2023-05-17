use proc_macro2::TokenStream;

// #[proc_macro_derive(DartEvent, attributes(event_ty))]
pub fn expand_enum_derive(_input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
  Ok(TokenStream::default())
}

// use flowy_ast::{ASTContainer, Ctxt};
// use proc_macro2::TokenStream;
//
// // #[proc_macro_derive(DartEvent, attributes(event_ty))]
// pub fn expand_enum_derive(input: &syn::DeriveInput) -> Result<TokenStream,
// Vec<syn::Error>> {     let ctxt = Ctxt::new();
//     let cont = match ASTContainer::from_ast(&ctxt, input) {
//         Some(cont) => cont,
//         None => return Err(ctxt.check().unwrap_err()),
//     };
//
//     let enum_ident = &cont.ident;
//     let pb_enum = cont.attrs.pb_enum_type().unwrap();
//
//     let build_display_pb_enum = cont.data.all_idents().map(|i| {
//         let a = format_ident!("{}", i.to_string());
//         let token_stream: TokenStream = quote! {
//             #enum_ident::#i => f.write_str(&#a)?,
//         };
//         token_stream
//     });
//
//     ctxt.check()?;
//
//     Ok(quote! {
//         impl std::fmt::Display for #enum_ident {
//            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result
// {                 match self {
//                     #(#build_display_pb_enum)*
//                 }
//             }
//         }
//     })
// }
