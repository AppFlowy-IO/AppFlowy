use dashmap::{DashMap, DashSet};
use flowy_ast::{ASTResult, TyInfo};
use flowy_codegen::ProtoCache;
use lazy_static::lazy_static;
use std::fs::File;
use std::io::Read;
use std::sync::atomic::{AtomicBool, Ordering};
use walkdir::WalkDir;

pub fn ident_category(ident: &syn::Ident) -> TypeCategory {
  let ident_str = ident.to_string();
  category_from_str(ident_str)
}

pub(crate) fn get_member_ident<'a>(
  ast_result: &ASTResult,
  member: &'a syn::Member,
) -> Option<&'a syn::Ident> {
  if let syn::Member::Named(ref ident) = member {
    Some(ident)
  } else {
    ast_result.error_spanned_by(
      member,
      "Unsupported member, shouldn't be self.0".to_string(),
    );
    None
  }
}

pub fn assert_bracket_ty_is_some(ast_result: &ASTResult, ty_info: &TyInfo) {
  if ty_info.bracket_ty_info.is_none() {
    ast_result.error_spanned_by(
      ty_info.ty,
      "Invalid bracketed type when gen de token steam".to_string(),
    );
  }
}

lazy_static! {
  static ref READ_FLAG: DashSet<String> = DashSet::new();
  static ref CACHE_INFO: DashMap<TypeCategory, Vec<String>> = DashMap::new();
  static ref IS_LOAD: AtomicBool = AtomicBool::new(false);
}

#[derive(Eq, Hash, PartialEq)]
pub enum TypeCategory {
  Array,
  Map,
  Str,
  Protobuf,
  Bytes,
  Enum,
  Opt,
  Primitive,
}
// auto generate, do not edit
pub fn category_from_str(type_str: String) -> TypeCategory {
  if !IS_LOAD.load(Ordering::SeqCst) {
    IS_LOAD.store(true, Ordering::SeqCst);
    // Dependents on another crate file is not good, just leave it here.
    // Maybe find another way to read the .cache in the future.
    let cache_dir = format!("{}/../flowy-codegen/.cache", env!("CARGO_MANIFEST_DIR"));
    for path in WalkDir::new(cache_dir)
      .into_iter()
      .filter_map(|e| e.ok())
      .filter(|e| e.path().file_stem().unwrap().to_str().unwrap() == "proto_cache")
      .map(|e| e.path().to_str().unwrap().to_string())
    {
      match read_file(&path) {
        None => {},
        Some(s) => {
          let cache: ProtoCache = serde_json::from_str(&s).unwrap();
          CACHE_INFO
            .entry(TypeCategory::Protobuf)
            .or_default()
            .extend(cache.structs);
          CACHE_INFO
            .entry(TypeCategory::Enum)
            .or_default()
            .extend(cache.enums);
        },
      }
    }
  }

  if let Some(protobuf_tys) = CACHE_INFO.get(&TypeCategory::Protobuf) {
    if protobuf_tys.contains(&type_str) {
      return TypeCategory::Protobuf;
    }
  }

  if let Some(enum_tys) = CACHE_INFO.get(&TypeCategory::Enum) {
    if enum_tys.contains(&type_str) {
      return TypeCategory::Enum;
    }
  }

  match type_str.as_str() {
    "Vec" => TypeCategory::Array,
    "HashMap" => TypeCategory::Map,
    "u8" => TypeCategory::Bytes,
    "String" => TypeCategory::Str,
    "Option" => TypeCategory::Opt,
    _ => TypeCategory::Primitive,
  }
}

fn read_file(path: &str) -> Option<String> {
  match File::open(path) {
    Ok(mut file) => {
      let mut content = String::new();
      match file.read_to_string(&mut content) {
        Ok(_) => Some(content),
        Err(_) => None,
      }
    },
    Err(_) => None,
  }
}
