#![allow(clippy::all)]
#![allow(unused_attributes)]
#![allow(unused_assignments)]
use crate::{attr, ty_ext::*, ASTResult, AttrsContainer};
use syn::{self, punctuated::Punctuated};

pub struct ASTContainer<'a> {
    /// The struct or enum name (without generics).
    pub ident: syn::Ident,
    /// Attributes on the structure.
    pub attrs: AttrsContainer,
    /// The contents of the struct or enum.
    pub data: ASTData<'a>,
}

impl<'a> ASTContainer<'a> {
    pub fn from_ast(ast_result: &ASTResult, ast: &'a syn::DeriveInput) -> Option<ASTContainer<'a>> {
        let attrs = AttrsContainer::from_ast(ast_result, ast);
        // syn::DeriveInput
        //  1. syn::DataUnion
        //  2. syn::DataStruct
        //  3. syn::DataEnum
        let data = match &ast.data {
            syn::Data::Struct(data) => {
                // https://docs.rs/syn/1.0.48/syn/struct.DataStruct.html
                let (style, fields) = struct_from_ast(ast_result, &data.fields);
                ASTData::Struct(style, fields)
            }
            syn::Data::Union(_) => {
                ast_result.error_spanned_by(ast, "Does not support derive for unions");
                return None;
            }
            syn::Data::Enum(data) => {
                // https://docs.rs/syn/1.0.48/syn/struct.DataEnum.html
                ASTData::Enum(enum_from_ast(ast_result, &ast.ident, &data.variants, &ast.attrs))
            }
        };

        let ident = ast.ident.clone();
        let item = ASTContainer { ident, attrs, data };
        Some(item)
    }
}

pub enum ASTData<'a> {
    Struct(ASTStyle, Vec<ASTField<'a>>),
    Enum(Vec<ASTEnumVariant<'a>>),
}

impl<'a> ASTData<'a> {
    pub fn all_fields(&'a self) -> Box<dyn Iterator<Item = &'a ASTField<'a>> + 'a> {
        match self {
            ASTData::Enum(variants) => Box::new(variants.iter().flat_map(|variant| variant.fields.iter())),
            ASTData::Struct(_, fields) => Box::new(fields.iter()),
        }
    }

    pub fn all_variants(&'a self) -> Box<dyn Iterator<Item = &'a attr::ASTEnumAttrVariant> + 'a> {
        match self {
            ASTData::Enum(variants) => {
                let iter = variants.iter().map(|variant| &variant.attrs);
                Box::new(iter)
            }
            ASTData::Struct(_, fields) => {
                let iter = fields.iter().flat_map(|_| None);
                Box::new(iter)
            }
        }
    }

    pub fn all_idents(&'a self) -> Box<dyn Iterator<Item = &'a syn::Ident> + 'a> {
        match self {
            ASTData::Enum(variants) => Box::new(variants.iter().map(|v| &v.ident)),
            ASTData::Struct(_, fields) => {
                let iter = fields.iter().flat_map(|f| match &f.member {
                    syn::Member::Named(ident) => Some(ident),
                    _ => None,
                });
                Box::new(iter)
            }
        }
    }
}

/// A variant of an enum.
pub struct ASTEnumVariant<'a> {
    pub ident: syn::Ident,
    pub attrs: attr::ASTEnumAttrVariant,
    pub style: ASTStyle,
    pub fields: Vec<ASTField<'a>>,
    pub original: &'a syn::Variant,
}

impl<'a> ASTEnumVariant<'a> {
    pub fn name(&self) -> String {
        self.ident.to_string()
    }
}

pub enum BracketCategory {
    Other,
    Opt,
    Vec,
    Map((String, String)),
}

pub struct ASTField<'a> {
    pub member: syn::Member,
    pub attrs: attr::ASTAttrField,
    pub ty: &'a syn::Type,
    pub original: &'a syn::Field,
    pub bracket_ty: Option<syn::Ident>,
    pub bracket_inner_ty: Option<syn::Ident>,
    pub bracket_category: Option<BracketCategory>,
}

impl<'a> ASTField<'a> {
    pub fn new(cx: &ASTResult, field: &'a syn::Field, index: usize) -> Result<Self, String> {
        let mut bracket_inner_ty = None;
        let mut bracket_ty = None;
        let mut bracket_category = Some(BracketCategory::Other);
        match parse_ty(cx, &field.ty) {
            Ok(Some(inner)) => {
                match inner.primitive_ty {
                    PrimitiveTy::Map(map_info) => {
                        bracket_category = Some(BracketCategory::Map((map_info.key.clone(), map_info.value)))
                    }
                    PrimitiveTy::Vec => {
                        bracket_category = Some(BracketCategory::Vec);
                    }
                    PrimitiveTy::Opt => {
                        bracket_category = Some(BracketCategory::Opt);
                    }
                    PrimitiveTy::Other => {
                        bracket_category = Some(BracketCategory::Other);
                    }
                }

                match *inner.bracket_ty_info {
                    Some(bracketed_inner_ty) => {
                        bracket_inner_ty = Some(bracketed_inner_ty.ident.clone());
                        bracket_ty = Some(inner.ident.clone());
                    }
                    None => {
                        bracket_ty = Some(inner.ident.clone());
                    }
                }
            }
            Ok(None) => {
                let msg = format!("Fail to get the ty inner type: {:?}", field);
                return Err(msg);
            }
            Err(e) => {
                eprintln!("ASTField parser failed: {:?} with error: {}", field, e);
                return Err(e);
            }
        }

        Ok(ASTField {
            member: match &field.ident {
                Some(ident) => syn::Member::Named(ident.clone()),
                None => syn::Member::Unnamed(index.into()),
            },
            attrs: attr::ASTAttrField::from_ast(cx, index, field),
            ty: &field.ty,
            original: field,
            bracket_ty,
            bracket_inner_ty,
            bracket_category,
        })
    }

    pub fn ty_as_str(&self) -> String {
        match self.bracket_inner_ty {
            Some(ref ty) => ty.to_string(),
            None => self.bracket_ty.as_ref().unwrap().clone().to_string(),
        }
    }

    #[allow(dead_code)]
    pub fn name(&self) -> Option<syn::Ident> {
        if let syn::Member::Named(ident) = &self.member {
            Some(ident.clone())
        } else {
            None
        }
    }

    pub fn is_option(&self) -> bool {
        attr::is_option(self.ty)
    }
}

#[derive(Copy, Clone)]
pub enum ASTStyle {
    Struct,
    /// Many unnamed fields.
    Tuple,
    /// One unnamed field.
    NewType,
    /// No fields.
    Unit,
}

pub fn struct_from_ast<'a>(cx: &ASTResult, fields: &'a syn::Fields) -> (ASTStyle, Vec<ASTField<'a>>) {
    match fields {
        syn::Fields::Named(fields) => (ASTStyle::Struct, fields_from_ast(cx, &fields.named)),
        syn::Fields::Unnamed(fields) if fields.unnamed.len() == 1 => {
            (ASTStyle::NewType, fields_from_ast(cx, &fields.unnamed))
        }
        syn::Fields::Unnamed(fields) => (ASTStyle::Tuple, fields_from_ast(cx, &fields.unnamed)),
        syn::Fields::Unit => (ASTStyle::Unit, Vec::new()),
    }
}

pub fn enum_from_ast<'a>(
    cx: &ASTResult,
    ident: &syn::Ident,
    variants: &'a Punctuated<syn::Variant, Token![,]>,
    enum_attrs: &[syn::Attribute],
) -> Vec<ASTEnumVariant<'a>> {
    variants
        .iter()
        .flat_map(|variant| {
            let attrs = attr::ASTEnumAttrVariant::from_ast(cx, ident, variant, enum_attrs);
            let (style, fields) = struct_from_ast(cx, &variant.fields);
            Some(ASTEnumVariant {
                ident: variant.ident.clone(),
                attrs,
                style,
                fields,
                original: variant,
            })
        })
        .collect()
}

fn fields_from_ast<'a>(cx: &ASTResult, fields: &'a Punctuated<syn::Field, Token![,]>) -> Vec<ASTField<'a>> {
    fields
        .iter()
        .enumerate()
        .flat_map(|(index, field)| ASTField::new(cx, field, index).ok())
        .collect()
}
