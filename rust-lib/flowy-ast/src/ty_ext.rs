use crate::Ctxt;
use quote::format_ident;
use syn::{self, AngleBracketedGenericArguments, PathSegment};

#[derive(Eq, PartialEq, Debug)]
pub enum PrimitiveTy {
    Map(MapInfo),
    Vec,
    Opt,
}

#[derive(Debug)]
pub struct TyInfo<'a> {
    pub ident: &'a syn::Ident,
    pub ty: &'a syn::Type,
    pub primitive_ty: PrimitiveTy,
    pub bracket_ty_info: Box<Option<TyInfo<'a>>>,
}

#[derive(Debug, Eq, PartialEq)]
pub struct MapInfo {
    pub key: String,
    pub value: String,
}

impl MapInfo {
    fn new(key: String, value: String) -> Self { MapInfo { key, value } }
}

impl<'a> TyInfo<'a> {
    #[allow(dead_code)]
    pub fn bracketed_ident(&'a self) -> &'a syn::Ident {
        match self.bracket_ty_info.as_ref() {
            Some(b_ty) => b_ty.ident,
            None => {
                panic!()
            },
        }
    }
}

pub fn parse_ty(ty: &syn::Type) -> Option<TyInfo> {
    // Type -> TypePath -> Path -> PathSegment -> PathArguments ->
    // AngleBracketedGenericArguments -> GenericArgument -> Type.
    if let syn::Type::Path(ref p) = ty {
        if p.path.segments.len() != 1 {
            return None;
        }

        let seg = match p.path.segments.last() {
            Some(seg) => seg,
            None => return None,
        };

        return if let syn::PathArguments::AngleBracketed(ref bracketed) = seg.arguments {
            match seg.ident.to_string().as_ref() {
                "HashMap" => generate_hashmap_ty_info(ty, seg, bracketed),
                "Vec" => generate_vec_ty_info(seg, bracketed),
                _ => {
                    panic!("Unsupported ty")
                },
            }
        } else {
            assert_eq!(seg.ident.to_string(), "Option".to_string());
            generate_option_ty_info(ty, seg)
        };
    }
    None
}

fn parse_bracketed(bracketed: &AngleBracketedGenericArguments) -> Vec<&syn::Type> {
    bracketed
        .args
        .iter()
        .flat_map(|arg| {
            if let syn::GenericArgument::Type(ref ty_in_bracket) = arg {
                Some(ty_in_bracket)
            } else {
                None
            }
        })
        .collect::<Vec<&syn::Type>>()
}

pub fn generate_hashmap_ty_info<'a>(
    ty: &'a syn::Type,
    path_segment: &'a PathSegment,
    bracketed: &'a AngleBracketedGenericArguments,
) -> Option<TyInfo<'a>> {
    // The args of map must greater than 2
    if bracketed.args.len() != 2 {
        return None;
    }
    let types = parse_bracketed(bracketed);
    let key = parse_ty(types[0]).unwrap().ident.to_string();
    let value = parse_ty(types[1]).unwrap().ident.to_string();
    let bracket_ty_info = Box::new(parse_ty(&types[1]));
    return Some(TyInfo {
        ident: &path_segment.ident,
        ty,
        primitive_ty: PrimitiveTy::Map(MapInfo::new(key, value)),
        bracket_ty_info,
    });
}

fn generate_option_ty_info<'a>(
    ty: &'a syn::Type,
    path_segment: &'a PathSegment,
) -> Option<TyInfo<'a>> {
    return Some(TyInfo {
        ident: &path_segment.ident,
        ty,
        primitive_ty: PrimitiveTy::Opt,
        bracket_ty_info: Box::new(None),
    });
}

fn generate_vec_ty_info<'a>(
    path_segment: &'a PathSegment,
    bracketed: &'a AngleBracketedGenericArguments,
) -> Option<TyInfo<'a>> {
    if bracketed.args.len() != 1 {
        return None;
    }
    if let syn::GenericArgument::Type(ref bracketed_type) = bracketed.args.first().unwrap() {
        let bracketed_ty_info = Box::new(parse_ty(&bracketed_type));
        return Some(TyInfo {
            ident: &path_segment.ident,
            ty: bracketed_type,
            primitive_ty: PrimitiveTy::Vec,
            bracket_ty_info: bracketed_ty_info,
        });
    }
    return None;
}
