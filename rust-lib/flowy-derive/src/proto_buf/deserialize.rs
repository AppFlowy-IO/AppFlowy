use crate::{derive_cache::TypeCategory, proto_buf::util::*};
use flowy_ast::*;
use proc_macro2::{Span, TokenStream};

pub fn make_de_token_steam(ctxt: &Ctxt, ast: &ASTContainer) -> Option<TokenStream> {
    let pb_ty = ast.attrs.pb_struct_type()?;
    let struct_ident = &ast.ident;

    let build_take_fields = ast
        .data
        .all_fields()
        .filter(|f| !f.attrs.skip_deserializing())
        .flat_map(|field| {
            if let Some(func) = field.attrs.deserialize_with() {
                let member = &field.member;
                Some(quote! { o.#member=#struct_ident::#func(pb); })
            } else if field.attrs.is_one_of() {
                token_stream_for_one_of(ctxt, field)
            } else {
                token_stream_for_field(ctxt, &field.member, &field.ty, false)
            }
        });

    let de_token_stream: TokenStream = quote! {
        impl std::convert::TryFrom<&Vec<u8>> for #struct_ident {
            type Error = String;
            fn try_from(bytes: &Vec<u8>) -> Result<Self, Self::Error> {
                let result: ::protobuf::ProtobufResult<crate::protobuf::#pb_ty> = ::protobuf::Message::parse_from_bytes(bytes);
                match result {
                    Ok(mut pb) => {
                        #struct_ident::try_from(&mut pb)
                    }
                    Err(e) => Err(format!("{:?}", e)),
                }
            }
        }

        impl std::convert::TryFrom<&mut crate::protobuf::#pb_ty> for #struct_ident {
            type Error = String;
            fn try_from(pb: &mut crate::protobuf::#pb_ty) -> Result<Self, Self::Error> {
                let mut o = Self::default();
                #(#build_take_fields)*
                Ok(o)
            }
        }
    }
    .into();

    Some(de_token_stream)
}

fn token_stream_for_one_of(ctxt: &Ctxt, field: &ASTField) -> Option<TokenStream> {
    let member = &field.member;
    let ident = get_member_ident(ctxt, member)?;
    let ty_info = parse_ty(ctxt, &field.ty)?;
    let has_func = format_ident!("has_{}", ident.to_string());
    match ident_category(ty_info.ident) {
        TypeCategory::Enum => {
            let get_func = format_ident!("get_{}", ident.to_string());
            let ty = ty_info.ty;
            Some(quote! {
                if pb.#has_func() {
                    let enum_de_from_pb = #ty::try_from(&mut pb.#get_func()).unwrap();
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
        _ => {
            let take_func = format_ident!("take_{}", ident.to_string());
            let ty = ty_info.ty;

            Some(quote! {
                if pb.#has_func() {
                    let struct_de_from_pb = #ty::try_from(&mut pb.#take_func()).unwrap();
                    o.#member=Some(struct_de_from_pb);
                }
            })
        },
    }
}

fn token_stream_for_field(
    ctxt: &Ctxt,
    member: &syn::Member,
    ty: &syn::Type,
    is_option: bool,
) -> Option<TokenStream> {
    let ident = get_member_ident(ctxt, member)?;
    let ty_info = parse_ty(ctxt, ty)?;
    match ident_category(ty_info.ident) {
        TypeCategory::Array => {
            assert_bracket_ty_is_some(ctxt, &ty_info);
            token_stream_for_vec(ctxt, &member, &ty_info.bracket_ty_info.unwrap())
        },
        TypeCategory::Map => {
            assert_bracket_ty_is_some(ctxt, &ty_info);
            token_stream_for_map(ctxt, &member, &ty_info.bracket_ty_info.unwrap())
        },
        TypeCategory::Protobuf => {
            // if the type wrapped by SingularPtrField, should call take first
            let take = syn::Ident::new("take", Span::call_site());
            // inner_type_ty would be the type of the field. (e.g value of AnyData)
            let ty = ty_info.ty;
            Some(quote! {
                let some_value = pb.#member.#take();
                if some_value.is_some() {
                    let struct_de_from_pb = #ty::try_from(&mut some_value.unwrap()).unwrap();
                    o.#member = struct_de_from_pb;
                }
            })
        },

        TypeCategory::Enum => {
            let ty = ty_info.ty;
            Some(quote! {
                let enum_de_from_pb = #ty::try_from(&mut pb.#member).unwrap();
                 o.#member = enum_de_from_pb;

            })
        },
        TypeCategory::Str => {
            let take_ident =
                syn::Ident::new(&format!("take_{}", ident.to_string()), Span::call_site());
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
        TypeCategory::Opt => {
            token_stream_for_field(ctxt, member, ty_info.bracket_ty_info.unwrap().ty, true)
        },
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
    ctxt: &Ctxt,
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
                .map(|mut m| #ty::try_from(&mut m).unwrap())
                .collect();
            })
        },
        TypeCategory::Bytes => {
            // Vec<u8>
            Some(quote! {
                o.#member = pb.#member.clone();
            })
        },
        _ => {
            // String
            let take_ident = format_ident!("take_{}", ident.to_string());
            Some(quote! {
                o.#member = pb.#take_ident().into_vec();
            })
        },
    }
}

fn token_stream_for_map(
    ctxt: &Ctxt,
    member: &syn::Member,
    bracketed_type: &TyInfo,
) -> Option<TokenStream> {
    let ident = get_member_ident(ctxt, member)?;

    let take_ident = format_ident!("take_{}", ident.to_string());
    let ty = bracketed_type.ty;

    match ident_category(bracketed_type.ident) {
        TypeCategory::Protobuf => Some(quote! {
             let mut m: std::collections::HashMap<String, #ty> = std::collections::HashMap::new();
              pb.#take_ident().into_iter().for_each(|(k,mut v)| {
                    m.insert(k.clone(), #ty::try_from(&mut v).unwrap());
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
