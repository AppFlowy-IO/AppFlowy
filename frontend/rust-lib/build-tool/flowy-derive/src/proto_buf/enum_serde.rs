use flowy_ast::*;
use proc_macro2::TokenStream;

#[allow(dead_code)]
pub fn make_enum_token_stream(_ast_result: &ASTResult, cont: &ASTContainer) -> Option<TokenStream> {
  let enum_ident = &cont.ident;
  let pb_enum = cont.pb_attrs.pb_enum_type()?;
  let build_to_pb_enum = cont.data.all_idents().map(|i| {
    let token_stream: TokenStream = quote! {
        #enum_ident::#i => crate::protobuf::#pb_enum::#i,
    };
    token_stream
  });

  let build_from_pb_enum = cont.data.all_idents().map(|i| {
    let token_stream: TokenStream = quote! {
        crate::protobuf::#pb_enum::#i => #enum_ident::#i,
    };
    token_stream
  });

  Some(quote! {
      impl std::convert::From<&crate::protobuf::#pb_enum> for #enum_ident {
          fn from(pb:&crate::protobuf::#pb_enum) -> Self {
              match pb {
                  #(#build_from_pb_enum)*
              }
          }
      }

      impl std::convert::From<#enum_ident> for  crate::protobuf::#pb_enum{
          fn from(o: #enum_ident) -> crate::protobuf::#pb_enum  {
              match o {
                  #(#build_to_pb_enum)*
              }
          }
      }
  })
}
