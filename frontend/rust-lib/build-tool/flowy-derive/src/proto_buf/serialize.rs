#![allow(clippy::while_let_on_iterator)]

use proc_macro2::TokenStream;

use flowy_ast::*;

use crate::proto_buf::util::{get_member_ident, ident_category, TypeCategory};

pub fn make_se_token_stream(ast_result: &ASTResult, ast: &ASTContainer) -> Option<TokenStream> {
  let pb_ty = ast.pb_attrs.pb_struct_type()?;
  let struct_ident = &ast.ident;

  let build_set_pb_fields = ast
    .data
    .all_fields()
    .filter(|f| !f.pb_attrs.skip_pb_serializing())
    .flat_map(|field| se_token_stream_for_field(ast_result, field, false));

  let se_token_stream: TokenStream = quote! {

      impl std::convert::TryInto<bytes::Bytes> for #struct_ident {
          type Error = ::protobuf::ProtobufError;
          fn try_into(self) -> Result<bytes::Bytes, Self::Error> {
              use protobuf::Message;
              let pb: crate::protobuf::#pb_ty = self.into();
              let bytes = pb.write_to_bytes()?;
              Ok(bytes::Bytes::from(bytes))
          }
      }

      impl std::convert::TryInto<Vec<u8>> for #struct_ident {
          type Error = ::protobuf::ProtobufError;
          fn try_into(self) -> Result<Vec<u8>, Self::Error> {
              use protobuf::Message;
              let pb: crate::protobuf::#pb_ty = self.into();
              let bytes = pb.write_to_bytes()?;
              Ok(bytes)
          }
      }

      impl std::convert::From<#struct_ident> for crate::protobuf::#pb_ty {
          fn from(mut o: #struct_ident) -> crate::protobuf::#pb_ty {
              let mut pb = crate::protobuf::#pb_ty::new();
              #(#build_set_pb_fields)*
              pb
          }
      }
  };

  Some(se_token_stream)
}

fn se_token_stream_for_field(
  ast_result: &ASTResult,
  field: &ASTField,
  _take: bool,
) -> Option<TokenStream> {
  if let Some(func) = &field.pb_attrs.serialize_pb_with() {
    let member = &field.member;
    Some(quote! { pb.#member=o.#func(); })
  } else if field.pb_attrs.is_one_of() {
    token_stream_for_one_of(ast_result, field)
  } else {
    gen_token_stream(ast_result, &field.member, field.ty, false)
  }
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

  let set_func = format_ident!("set_{}", ident.to_string());

  match ident_category(bracketed_ty_info.unwrap().ident) {
    TypeCategory::Protobuf => Some(quote! {
        match o.#member {
            Some(s) => { pb.#set_func(s.into()) }
            None => {}
        }
    }),
    TypeCategory::Enum => Some(quote! {
        match o.#member {
            Some(s) => { pb.#set_func(s.into()) }
            None => {}
        }
    }),
    _ => Some(quote! {
        match o.#member {
            Some(ref s) => { pb.#set_func(s.clone()) }
            None => {}
        }
    }),
  }
}

fn gen_token_stream(
  ast_result: &ASTResult,
  member: &syn::Member,
  ty: &syn::Type,
  is_option: bool,
) -> Option<TokenStream> {
  let ty_info = match parse_ty(ast_result, ty) {
    Ok(ty_info) => ty_info,
    Err(e) => {
      eprintln!("gen_token_stream failed: {:?} with error: {}", member, e);
      panic!();
    },
  }?;
  match ident_category(ty_info.ident) {
    TypeCategory::Array => {
      token_stream_for_vec(ast_result, member, ty_info.bracket_ty_info.unwrap().ty)
    },
    TypeCategory::Map => {
      token_stream_for_map(ast_result, member, ty_info.bracket_ty_info.unwrap().ty)
    },
    TypeCategory::Str => {
      if is_option {
        Some(quote! {
            match o.#member {
                Some(ref s) => { pb.#member = s.to_string().clone();  }
                None => {  pb.#member = String::new(); }
            }
        })
      } else {
        Some(quote! { pb.#member = o.#member.clone(); })
      }
    },
    TypeCategory::Protobuf => {
      Some(quote! { pb.#member =  ::protobuf::SingularPtrField::some(o.#member.into()); })
    },
    TypeCategory::Opt => gen_token_stream(
      ast_result,
      member,
      ty_info.bracket_ty_info.unwrap().ty,
      true,
    ),
    TypeCategory::Enum => {
      // let pb_enum_ident = format_ident!("{}", ty_info.ident.to_string());
      // Some(quote! {
      // flowy_protobuf::#pb_enum_ident::from_i32(self.#member.value()).unwrap();
      // })
      Some(quote! {
          pb.#member = o.#member.into();
      })
    },
    _ => Some(quote! { pb.#member = o.#member; }),
  }
}

// e.g. pub cells: Vec<CellData>, the member will be cells, ty would be Vec
fn token_stream_for_vec(
  ast_result: &ASTResult,
  member: &syn::Member,
  ty: &syn::Type,
) -> Option<TokenStream> {
  let ty_info = match parse_ty(ast_result, ty) {
    Ok(ty_info) => ty_info,
    Err(e) => {
      eprintln!(
        "token_stream_for_vec failed: {:?} with error: {}",
        member, e
      );
      panic!();
    },
  }?;

  match ident_category(ty_info.ident) {
    TypeCategory::Protobuf => Some(quote! {
        pb.#member = ::protobuf::RepeatedField::from_vec(
            o.#member
            .into_iter()
            .map(|m| m.into())
            .collect());
    }),
    TypeCategory::Bytes => Some(quote! { pb.#member = o.#member.clone(); }),
    TypeCategory::Primitive => Some(quote! {
        pb.#member = o.#member.clone();
    }),
    _ => Some(quote! {
        pb.#member = ::protobuf::RepeatedField::from_vec(o.#member.clone());
    }),
  }
}

// e.g. pub cells: HashMap<xx, xx>
fn token_stream_for_map(
  ast_result: &ASTResult,
  member: &syn::Member,
  ty: &syn::Type,
) -> Option<TokenStream> {
  // The key of the hashmap must be string
  let ty_info = match parse_ty(ast_result, ty) {
    Ok(ty_info) => ty_info,
    Err(e) => {
      eprintln!(
        "token_stream_for_map failed: {:?} with error: {}",
        member, e
      );
      panic!();
    },
  }?;
  let value_ty = ty_info.ty;
  match ident_category(ty_info.ident) {
    TypeCategory::Protobuf => Some(quote! {
        let mut m: std::collections::HashMap<String, crate::protobuf::#value_ty> = std::collections::HashMap::new();
        o.#member.into_iter().for_each(|(k,v)| {
            m.insert(k.clone(), v.into());
        });
        pb.#member = m;
    }),
    _ => Some(quote! {
        let mut m: std::collections::HashMap<String, #value_ty> = std::collections::HashMap::new();
          o.#member.iter().for_each(|(k,v)| {
             m.insert(k.clone(), v.clone());
          });
        pb.#member = m;
    }),
  }
}
