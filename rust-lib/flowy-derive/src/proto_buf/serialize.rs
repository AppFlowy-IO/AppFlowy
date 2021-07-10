use crate::{derive_cache::TypeCategory, proto_buf::util::ident_category};
use flowy_ast::*;
use proc_macro2::TokenStream;

pub fn make_se_token_stream(ctxt: &Ctxt, ast: &ASTContainer) -> Option<TokenStream> {
    let pb_ty = ast.attrs.pb_struct_type()?;
    let struct_ident = &ast.ident;

    let build_set_pb_fields = ast
        .data
        .all_fields()
        .filter(|f| !f.attrs.skip_serializing())
        .flat_map(|field| se_token_stream_for_field(&ctxt, &field, false));

    // let _build_set_fields = ast
    //     .data
    //     .all_fields()
    //     .filter(|f| !f.attrs.skip_serializing())
    //     .flat_map(|field| se_token_stream_for_field(&ctxt, &field, false));

    let se_token_stream: TokenStream = quote! {

        impl std::convert::TryInto<Vec<u8>> for #struct_ident {
            type Error = String;
            fn try_into(self) -> Result<Vec<u8>, Self::Error> {
                use protobuf::Message;
                let pb: crate::protobuf::#pb_ty = self.try_into()?;
                let result: ::protobuf::ProtobufResult<Vec<u8>> = pb.write_to_bytes();
                match result {
                    Ok(bytes) => { Ok(bytes) },
                    Err(e) => { Err(format!("{:?}", e)) }
                }
            }
        }

        impl std::convert::TryInto<crate::protobuf::#pb_ty> for #struct_ident {
            type Error = String;
            fn try_into(self) -> Result<crate::protobuf::#pb_ty, Self::Error> {
                let mut pb = crate::protobuf::#pb_ty::new();
                #(#build_set_pb_fields)*
                Ok(pb)
            }
        }
    }
    .into();

    Some(se_token_stream)
}

fn se_token_stream_for_field(ctxt: &Ctxt, field: &ASTField, _take: bool) -> Option<TokenStream> {
    if let Some(func) = &field.attrs.serialize_with() {
        let member = &field.member;
        Some(quote! { pb.#member=self.#func(); })
    } else if field.attrs.is_one_of() {
        let member = &field.member;
        match &field.member {
            syn::Member::Named(ref ident) => {
                let set_func = format_ident!("set_{}", ident.to_string());
                Some(quote! {
                    match self.#member {
                        Some(ref s) => { pb.#set_func(s.clone()) }
                        None => {}
                    }
                })
            },
            _ => {
                ctxt.error_spanned_by(member, format!("Unsupported member, get member ident fail"));
                None
            },
        }
    } else {
        gen_token_stream(ctxt, &field.member, &field.ty, false)
    }
}

fn gen_token_stream(
    ctxt: &Ctxt,
    member: &syn::Member,
    ty: &syn::Type,
    is_option: bool,
) -> Option<TokenStream> {
    let ty_info = parse_ty(ctxt, ty)?;
    match ident_category(ty_info.ident) {
        TypeCategory::Array => token_stream_for_vec(ctxt, &member, &ty_info.ty),
        TypeCategory::Map => {
            token_stream_for_map(ctxt, &member, &ty_info.bracket_ty_info.unwrap().ty)
        },
        TypeCategory::Str => {
            if is_option {
                Some(quote! {
                    match self.#member {
                        Some(ref s) => { pb.#member = s.to_string().clone();  }
                        None => {  pb.#member = String::new(); }
                    }
                })
            } else {
                Some(quote! { pb.#member = self.#member.clone(); })
            }
        },
        TypeCategory::Protobuf => Some(
            quote! { pb.#member =  ::protobuf::SingularPtrField::some(self.#member.try_into().unwrap()); },
        ),
        TypeCategory::Opt => {
            gen_token_stream(ctxt, member, ty_info.bracket_ty_info.unwrap().ty, true)
        },
        TypeCategory::Enum => {
            // let pb_enum_ident = format_ident!("{}", ty_info.ident.to_string());
            // Some(quote! {
            // flowy_protobuf::#pb_enum_ident::from_i32(self.#member.value()).unwrap();
            // })
            Some(quote! {
                pb.#member = self.#member.try_into().unwrap();
            })
        },
        _ => Some(quote! { pb.#member = self.#member; }),
    }
}

// e.g. pub cells: Vec<CellData>, the memeber will be cells, ty would be Vec
fn token_stream_for_vec(ctxt: &Ctxt, member: &syn::Member, ty: &syn::Type) -> Option<TokenStream> {
    let ty_info = parse_ty(ctxt, ty)?;
    match ident_category(ty_info.ident) {
        TypeCategory::Protobuf => Some(quote! {
            pb.#member = ::protobuf::RepeatedField::from_vec(
                self.#member
                .iter()
                .map(|m| m.try_into().unwrap())
                .collect());
        }),
        TypeCategory::Bytes => Some(quote! { pb.#member = self.#member.clone(); }),

        _ => Some(quote! {
            pb.#member = ::protobuf::RepeatedField::from_vec(self.#member.clone());
        }),
    }
}

// e.g. pub cells: HashMap<xx, xx>
fn token_stream_for_map(ctxt: &Ctxt, member: &syn::Member, ty: &syn::Type) -> Option<TokenStream> {
    // The key of the hashmap must be string
    let flowy_protobuf = format_ident!("flowy_protobuf");
    let ty_info = parse_ty(ctxt, ty)?;
    match ident_category(ty_info.ident) {
        TypeCategory::Protobuf => {
            let value_type = ty_info.ident;
            Some(quote! {
                let mut m: std::collections::HashMap<String, #flowy_protobuf::#value_type> = std::collections::HashMap::new();
                self.#member.iter().for_each(|(k,v)| {
                    m.insert(k.clone(), v.try_into().unwrap());
                });
                pb.#member = m;
            })
        },

        _ => {
            let value_type = ty_info.ident;
            Some(quote! {
                let mut m: std::collections::HashMap<String, #flowy_protobuf::#value_type> = std::collections::HashMap::new();
                  self.#member.iter().for_each(|(k,v)| {
                     m.insert(k.clone(), v.clone());
                  });
                pb.#member = m;
            })
        },
    }
}
