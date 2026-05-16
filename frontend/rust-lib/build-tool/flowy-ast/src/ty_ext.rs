use crate::ASTResult;
use syn::{self, AngleBracketedGenericArguments, PathSegment};

#[derive(Eq, PartialEq, Debug)]
pub enum PrimitiveTy {
  Map(MapInfo),
  Vec,
  Opt,
  Other,
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
  fn new(key: String, value: String) -> Self {
    MapInfo { key, value }
  }
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

pub fn parse_ty<'a>(
  ast_result: &ASTResult,
  ty: &'a syn::Type,
) -> Result<Option<TyInfo<'a>>, String> {
  // Type -> TypePath -> Path -> PathSegment -> PathArguments ->
  // AngleBracketedGenericArguments -> GenericArgument -> Type.
  if let syn::Type::Path(ref p) = ty {
    if p.path.segments.len() != 1 {
      return Ok(None);
    }

    let seg = match p.path.segments.last() {
      Some(seg) => seg,
      None => return Ok(None),
    };

    let _is_option = seg.ident == "Option";

    return if let syn::PathArguments::AngleBracketed(ref bracketed) = seg.arguments {
      match seg.ident.to_string().as_ref() {
        "HashMap" => generate_hashmap_ty_info(ast_result, ty, seg, bracketed),
        "Vec" => generate_vec_ty_info(ast_result, seg, bracketed),
        "Option" => generate_option_ty_info(ast_result, ty, seg, bracketed),
        _ => {
          let msg = format!("Unsupported type: {}", seg.ident);
          ast_result.error_spanned_by(&seg.ident, &msg);
          return Err(msg);
        },
      }
    } else {
      return Ok(Some(TyInfo {
        ident: &seg.ident,
        ty,
        primitive_ty: PrimitiveTy::Other,
        bracket_ty_info: Box::new(None),
      }));
    };
  }
  Err("Unsupported inner type, get inner type fail".to_string())
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
  ast_result: &ASTResult,
  ty: &'a syn::Type,
  path_segment: &'a PathSegment,
  bracketed: &'a AngleBracketedGenericArguments,
) -> Result<Option<TyInfo<'a>>, String> {
  // The args of map must greater than 2
  if bracketed.args.len() != 2 {
    return Ok(None);
  }
  let types = parse_bracketed(bracketed);
  let key = parse_ty(ast_result, types[0])?.unwrap().ident.to_string();
  let value = parse_ty(ast_result, types[1])?.unwrap().ident.to_string();
  let bracket_ty_info = Box::new(parse_ty(ast_result, types[1])?);
  Ok(Some(TyInfo {
    ident: &path_segment.ident,
    ty,
    primitive_ty: PrimitiveTy::Map(MapInfo::new(key, value)),
    bracket_ty_info,
  }))
}

fn generate_option_ty_info<'a>(
  ast_result: &ASTResult,
  ty: &'a syn::Type,
  path_segment: &'a PathSegment,
  bracketed: &'a AngleBracketedGenericArguments,
) -> Result<Option<TyInfo<'a>>, String> {
  assert_eq!(path_segment.ident.to_string(), "Option".to_string());
  let types = parse_bracketed(bracketed);
  let bracket_ty_info = Box::new(parse_ty(ast_result, types[0])?);
  Ok(Some(TyInfo {
    ident: &path_segment.ident,
    ty,
    primitive_ty: PrimitiveTy::Opt,
    bracket_ty_info,
  }))
}

fn generate_vec_ty_info<'a>(
  ast_result: &ASTResult,
  path_segment: &'a PathSegment,
  bracketed: &'a AngleBracketedGenericArguments,
) -> Result<Option<TyInfo<'a>>, String> {
  if bracketed.args.len() != 1 {
    return Ok(None);
  }
  if let syn::GenericArgument::Type(ref bracketed_type) = bracketed.args.first().unwrap() {
    let bracketed_ty_info = Box::new(parse_ty(ast_result, bracketed_type)?);
    return Ok(Some(TyInfo {
      ident: &path_segment.ident,
      ty: bracketed_type,
      primitive_ty: PrimitiveTy::Vec,
      bracket_ty_info: bracketed_ty_info,
    }));
  }
  Ok(None)
}
