use proc_macro2::{Span, TokenStream};

use flowy_ast::*;

use crate::proto_buf::util::*;

pub fn make_de_token_steam(ast_result: &ASTResult, ast: &ASTContainer) -> Option<TokenStream> {
  let pb_ty = ast.pb_attrs.pb_struct_type()?;
  let struct_ident = &ast.ident;

  let build_take_fields = ast
    .data
    .all_fields()
    .filter(|f| !f.pb_attrs.skip_pb_deserializing())
    .flat_map(|field| {
      if let Some(func) = field.pb_attrs.deserialize_pb_with() {
        let member = &field.member;
        Some(quote! { o.#member=#struct_ident::#func(pb); })
      } else if field.pb_attrs.is_one_of() {
        token_stream_for_one_of(ast_result, field)
      } else {
        token_stream_for_field(ast_result, &field.member, field.ty, false)
      }
    });

  let de_token_stream: TokenStream = quote! {
      impl std::convert::TryFrom<bytes::Bytes> for #struct_ident {
          type Error = ::protobuf::ProtobufError;
          fn try_from(bytes: bytes::Bytes) -> Result<Self, Self::Error> {
              Self::try_from(&bytes)
          }
      }

      impl std::convert::TryFrom<&bytes::Bytes> for #struct_ident {
          type Error = ::protobuf::ProtobufError;
          fn try_from(bytes: &bytes::Bytes) -> Result<Self, Self::Error> {
              let pb: crate::protobuf::#pb_ty = ::protobuf::Message::parse_from_bytes(bytes)?;
              Ok(#struct_ident::from(pb))
          }
      }

      impl std::convert::TryFrom<&[u8]> for #struct_ident {
          type Error = ::protobuf::ProtobufError;
          fn try_from(bytes: &[u8]) -> Result<Self, Self::Error> {
              let pb: crate::protobuf::#pb_ty = ::protobuf::Message::parse_from_bytes(bytes)?;
              Ok(#struct_ident::from(pb))
          }
      }

      impl std::convert::From<crate::protobuf::#pb_ty> for #struct_ident {
          fn from(mut pb: crate::protobuf::#pb_ty) -> Self {
              let mut o = Self::default();
              #(#build_take_fields)*
              o
          }
      }
  };

  Some(de_token_stream)
  // None
}

fn token_stream_for_one_of(ast_result: &ASTResult, field: &ASTField) -> Option<TokenStream> {
  let member = &field.member;
  let ident = get_member_ident(ast_result, member)?;
  let ty_info = match parse_ty(ast_result, field.ty) {
    Ok(ty_info) => ty_info,
    Err(e) => {
      eprintln!(
        "token_stream_for_one_of failed: {:?} with error: {}",
        member, e
      );
      panic!();
    },
  }?;
  let bracketed_ty_info = ty_info.bracket_ty_info.as_ref().as_ref();
  let has_func = format_ident!("has_{}", ident.to_string());
  match ident_category(bracketed_ty_info.unwrap().ident) {
    TypeCategory::Enum => {
      let get_func = format_ident!("get_{}", ident.to_string());
      let ty = bracketed_ty_info.unwrap().ty;
      Some(quote! {
          if pb.#has_func() {
              let enum_de_from_pb = #ty::from(&pb.#get_func());
              o.#member = Some(enum_de_from_pb);
          }
      })
    },
    TypeCategory::Primitive => {
      let get_func = format_ident!("get_{}", ident.to_string());
      Some(quote! {
          if pb.#has_func() {
              o.#member=Some(pb.#get_func());
          }
      })
    },
    TypeCategory::Str => {
      let take_func = format_ident!("take_{}", ident.to_string());
      Some(quote! {
          if pb.#has_func() {
              o.#member=Some(pb.#take_func());
          }
      })
    },
    TypeCategory::Array => {
      let take_func = format_ident!("take_{}", ident.to_string());
      Some(quote! {
          if pb.#has_func() {
              o.#member=Some(pb.#take_func());
          }
      })
    },
    _ => {
      let take_func = format_ident!("take_{}", ident.to_string());
      let ty = bracketed_ty_info.unwrap().ty;
      Some(quote! {
          if pb.#has_func() {
              let val = #ty::from(pb.#take_func());
              o.#member=Some(val);
          }
      })
    },
  }
}

fn token_stream_for_field(
  ast_result: &ASTResult,
  member: &syn::Member,
  ty: &syn::Type,
  is_option: bool,
) -> Option<TokenStream> {
  let ident = get_member_ident(ast_result, member)?;
  let ty_info = match parse_ty(ast_result, ty) {
    Ok(ty_info) => ty_info,
    Err(e) => {
      eprintln!("token_stream_for_field: {:?} with error: {}", member, e);
      panic!()
    },
  }?;
  match ident_category(ty_info.ident) {
    TypeCategory::Array => {
      assert_bracket_ty_is_some(ast_result, &ty_info);
      token_stream_for_vec(ast_result, member, &ty_info.bracket_ty_info.unwrap())
    },
    TypeCategory::Map => {
      assert_bracket_ty_is_some(ast_result, &ty_info);
      token_stream_for_map(ast_result, member, &ty_info.bracket_ty_info.unwrap())
    },
    TypeCategory::Protobuf => {
      // if the type wrapped by SingularPtrField, should call take first
      let take = syn::Ident::new("take", Span::call_site());
      // inner_type_ty would be the type of the field. (e.g value of AnyData)
      let ty = ty_info.ty;
      Some(quote! {
          let some_value = pb.#member.#take();
          if some_value.is_some() {
              let struct_de_from_pb = #ty::from(some_value.unwrap());
              o.#member = struct_de_from_pb;
          }
      })
    },

    TypeCategory::Enum => {
      let ty = ty_info.ty;
      Some(quote! {
          let enum_de_from_pb = #ty::from(&pb.#member);
           o.#member = enum_de_from_pb;

      })
    },
    TypeCategory::Str => {
      let take_ident = syn::Ident::new(&format!("take_{}", ident), Span::call_site());
      if is_option {
        Some(quote! {
            if pb.#member.is_empty() {
                o.#member = None;
            } else {
                o.#member = Some(pb.#take_ident());
            }
        })
      } else {
        Some(quote! {
            o.#member = pb.#take_ident();
        })
      }
    },
    TypeCategory::Opt => token_stream_for_field(
      ast_result,
      member,
      ty_info.bracket_ty_info.unwrap().ty,
      true,
    ),
    TypeCategory::Primitive | TypeCategory::Bytes => {
      // eprintln!("😄 #{:?}", &field.name().unwrap());
      if is_option {
        Some(quote! { o.#member = Some(pb.#member.clone()); })
      } else {
        Some(quote! { o.#member = pb.#member.clone(); })
      }
    },
  }
}

fn token_stream_for_vec(
  ctxt: &ASTResult,
  member: &syn::Member,
  bracketed_type: &TyInfo,
) -> Option<TokenStream> {
  let ident = get_member_ident(ctxt, member)?;

  match ident_category(bracketed_type.ident) {
    TypeCategory::Protobuf => {
      let ty = bracketed_type.ty;
      // Deserialize from pb struct of type vec, should call take_xx(), get the
      // repeated_field and then calling the into_iter。
      let take_ident = format_ident!("take_{}", ident.to_string());
      Some(quote! {
          o.#member = pb.#take_ident()
          .into_iter()
          .map(|m| #ty::from(m))
          .collect();
      })
    },
    TypeCategory::Bytes => {
      // Vec<u8>
      Some(quote! {
          o.#member = pb.#member.clone();
      })
    },
    TypeCategory::Str => {
      let take_ident = format_ident!("take_{}", ident.to_string());
      Some(quote! {
          o.#member = pb.#take_ident().into_vec();
      })
    },
    _ => {
      let take_ident = format_ident!("take_{}", ident.to_string());
      Some(quote! {
          o.#member = pb.#take_ident();
      })
    },
  }
}

fn token_stream_for_map(
  ast_result: &ASTResult,
  member: &syn::Member,
  ty_info: &TyInfo,
) -> Option<TokenStream> {
  let ident = get_member_ident(ast_result, member)?;
  let take_ident = format_ident!("take_{}", ident.to_string());
  let ty = ty_info.ty;

  match ident_category(ty_info.ident) {
    TypeCategory::Protobuf => Some(quote! {
         let mut m: std::collections::HashMap<String, #ty> = std::collections::HashMap::new();
          pb.#take_ident().into_iter().for_each(|(k,v)| {
                m.insert(k.clone(), #ty::from(v));
          });
         o.#member = m;
    }),
    _ => Some(quote! {
        let mut m: std::collections::HashMap<String, #ty> = std::collections::HashMap::new();
        pb.#take_ident().into_iter().for_each(|(k,mut v)| {
            m.insert(k.clone(), v);
        });
        o.#member = m;
    }),
  }
}
