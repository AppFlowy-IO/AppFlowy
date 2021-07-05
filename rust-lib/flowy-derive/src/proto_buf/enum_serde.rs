use flowy_ast::*;
use proc_macro2::TokenStream;

#[allow(dead_code)]
pub fn make_enum_token_stream(_ctxt: &Ctxt, cont: &ASTContainer) -> Option<TokenStream> {
    let enum_ident = &cont.ident;
    let pb_enum = cont.attrs.pb_enum_type()?;
    let _build_to_pb_enum = cont.data.all_idents().map(|i| {
        let token_stream: TokenStream = quote! {
            #enum_ident::#i => #pb_enum::#i,
        };
        token_stream
    });

    let build_from_pb_enum = cont.data.all_idents().map(|i| {
        let token_stream: TokenStream = quote! {
            #pb_enum::#i => #enum_ident::#i,
        };
        token_stream
    });

    Some(quote! {
        impl std::convert::TryFrom<#pb_enum> for #enum_ident {
            type Error = String;
            fn try_from(pb: #pb_enum) -> Result<Self, Self::Error> {
                match field_type {
                    #(#build_from_pb_enum)*
                }
            }
        }
    })
}
