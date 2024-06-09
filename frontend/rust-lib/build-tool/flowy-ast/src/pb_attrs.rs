#![allow(clippy::all)]

use crate::{symbol::*, ASTResult};
use proc_macro2::{Group, Span, TokenStream, TokenTree};
use quote::ToTokens;
use syn::{
  self,
  parse::{self, Parse},
  Meta::{List, NameValue, Path},
  NestedMeta::{Lit, Meta},
};

#[allow(dead_code)]
pub struct PBAttrsContainer {
  name: String,
  pb_struct_type: Option<syn::Type>,
  pb_enum_type: Option<syn::Type>,
}

impl PBAttrsContainer {
  /// Extract out the `#[pb(...)]` attributes from an item.
  pub fn from_ast(ast_result: &ASTResult, item: &syn::DeriveInput) -> Self {
    let mut pb_struct_type = ASTAttr::none(ast_result, PB_STRUCT);
    let mut pb_enum_type = ASTAttr::none(ast_result, PB_ENUM);
    for meta_item in item
      .attrs
      .iter()
      .flat_map(|attr| get_pb_meta_items(ast_result, attr))
      .flatten()
    {
      match &meta_item {
        // Parse `#[pb(struct = "Type")]
        Meta(NameValue(m)) if m.path == PB_STRUCT => {
          if let Ok(into_ty) = parse_lit_into_ty(ast_result, PB_STRUCT, &m.lit) {
            pb_struct_type.set_opt(&m.path, Some(into_ty));
          }
        },

        // Parse `#[pb(enum = "Type")]
        Meta(NameValue(m)) if m.path == PB_ENUM => {
          if let Ok(into_ty) = parse_lit_into_ty(ast_result, PB_ENUM, &m.lit) {
            pb_enum_type.set_opt(&m.path, Some(into_ty));
          }
        },

        Meta(meta_item) => {
          let path = meta_item
            .path()
            .into_token_stream()
            .to_string()
            .replace(' ', "");
          ast_result.error_spanned_by(
            meta_item.path(),
            format!("unknown container attribute `{}`", path),
          );
        },

        Lit(lit) => {
          ast_result.error_spanned_by(lit, "unexpected literal in container attribute");
        },
      }
    }
    match &item.data {
      syn::Data::Struct(_) => {
        pb_struct_type.set_if_none(default_pb_type(&ast_result, &item.ident));
      },
      syn::Data::Enum(_) => {
        pb_enum_type.set_if_none(default_pb_type(&ast_result, &item.ident));
      },
      _ => {},
    }

    PBAttrsContainer {
      name: item.ident.to_string(),
      pb_struct_type: pb_struct_type.get(),
      pb_enum_type: pb_enum_type.get(),
    }
  }

  pub fn pb_struct_type(&self) -> Option<&syn::Type> {
    self.pb_struct_type.as_ref()
  }

  pub fn pb_enum_type(&self) -> Option<&syn::Type> {
    self.pb_enum_type.as_ref()
  }
}

pub struct ASTAttr<'c, T> {
  ast_result: &'c ASTResult,
  name: Symbol,
  tokens: TokenStream,
  value: Option<T>,
}

impl<'c, T> ASTAttr<'c, T> {
  pub(crate) fn none(ast_result: &'c ASTResult, name: Symbol) -> Self {
    ASTAttr {
      ast_result,
      name,
      tokens: TokenStream::new(),
      value: None,
    }
  }

  pub(crate) fn set<A: ToTokens>(&mut self, obj: A, value: T) {
    let tokens = obj.into_token_stream();

    if self.value.is_some() {
      self
        .ast_result
        .error_spanned_by(tokens, format!("duplicate attribute `{}`", self.name));
    } else {
      self.tokens = tokens;
      self.value = Some(value);
    }
  }

  fn set_opt<A: ToTokens>(&mut self, obj: A, value: Option<T>) {
    if let Some(value) = value {
      self.set(obj, value);
    }
  }

  pub(crate) fn set_if_none(&mut self, value: T) {
    if self.value.is_none() {
      self.value = Some(value);
    }
  }

  pub(crate) fn get(self) -> Option<T> {
    self.value
  }

  #[allow(dead_code)]
  fn get_with_tokens(self) -> Option<(TokenStream, T)> {
    match self.value {
      Some(v) => Some((self.tokens, v)),
      None => None,
    }
  }
}

pub struct PBStructAttrs {
  #[allow(dead_code)]
  name: String,
  pb_index: Option<syn::LitInt>,
  pb_one_of: bool,
  skip_pb_serializing: bool,
  skip_pb_deserializing: bool,
  serialize_pb_with: Option<syn::ExprPath>,
  deserialize_pb_with: Option<syn::ExprPath>,
}

pub fn is_recognizable_field(field: &syn::Field) -> bool {
  field
    .attrs
    .iter()
    .any(|attr| is_recognizable_attribute(attr))
}

impl PBStructAttrs {
  /// Extract out the `#[pb(...)]` attributes from a struct field.
  pub fn from_ast(ast_result: &ASTResult, index: usize, field: &syn::Field) -> Self {
    let mut pb_index = ASTAttr::none(ast_result, PB_INDEX);
    let mut pb_one_of = BoolAttr::none(ast_result, PB_ONE_OF);
    let mut serialize_pb_with = ASTAttr::none(ast_result, SERIALIZE_PB_WITH);
    let mut skip_pb_serializing = BoolAttr::none(ast_result, SKIP_PB_SERIALIZING);
    let mut deserialize_pb_with = ASTAttr::none(ast_result, DESERIALIZE_PB_WITH);
    let mut skip_pb_deserializing = BoolAttr::none(ast_result, SKIP_PB_DESERIALIZING);

    let ident = match &field.ident {
      Some(ident) => ident.to_string(),
      None => index.to_string(),
    };

    for meta_item in field
      .attrs
      .iter()
      .flat_map(|attr| get_pb_meta_items(ast_result, attr))
      .flatten()
    {
      match &meta_item {
        // Parse `#[pb(skip)]`
        Meta(Path(word)) if word == SKIP => {
          skip_pb_serializing.set_true(word);
          skip_pb_deserializing.set_true(word);
        },

        // Parse '#[pb(index = x)]'
        Meta(NameValue(m)) if m.path == PB_INDEX => {
          if let syn::Lit::Int(lit) = &m.lit {
            pb_index.set(&m.path, lit.clone());
          }
        },

        // Parse `#[pb(one_of)]`
        Meta(Path(path)) if path == PB_ONE_OF => {
          pb_one_of.set_true(path);
        },

        // Parse `#[pb(serialize_pb_with = "...")]`
        Meta(NameValue(m)) if m.path == SERIALIZE_PB_WITH => {
          if let Ok(path) = parse_lit_into_expr_path(ast_result, SERIALIZE_PB_WITH, &m.lit) {
            serialize_pb_with.set(&m.path, path);
          }
        },

        // Parse `#[pb(deserialize_pb_with = "...")]`
        Meta(NameValue(m)) if m.path == DESERIALIZE_PB_WITH => {
          if let Ok(path) = parse_lit_into_expr_path(ast_result, DESERIALIZE_PB_WITH, &m.lit) {
            deserialize_pb_with.set(&m.path, path);
          }
        },

        Meta(meta_item) => {
          let path = meta_item
            .path()
            .into_token_stream()
            .to_string()
            .replace(' ', "");
          ast_result.error_spanned_by(
            meta_item.path(),
            format!("unknown pb field attribute `{}`", path),
          );
        },

        Lit(lit) => {
          ast_result.error_spanned_by(lit, "unexpected literal in field attribute");
        },
      }
    }

    PBStructAttrs {
      name: ident,
      pb_index: pb_index.get(),
      pb_one_of: pb_one_of.get(),
      skip_pb_serializing: skip_pb_serializing.get(),
      skip_pb_deserializing: skip_pb_deserializing.get(),
      serialize_pb_with: serialize_pb_with.get(),
      deserialize_pb_with: deserialize_pb_with.get(),
    }
  }

  #[allow(dead_code)]
  pub fn pb_index(&self) -> Option<String> {
    self
      .pb_index
      .as_ref()
      .map(|lit| lit.base10_digits().to_string())
  }

  pub fn is_one_of(&self) -> bool {
    self.pb_one_of
  }

  pub fn serialize_pb_with(&self) -> Option<&syn::ExprPath> {
    self.serialize_pb_with.as_ref()
  }

  pub fn deserialize_pb_with(&self) -> Option<&syn::ExprPath> {
    self.deserialize_pb_with.as_ref()
  }

  pub fn skip_pb_serializing(&self) -> bool {
    self.skip_pb_serializing
  }

  pub fn skip_pb_deserializing(&self) -> bool {
    self.skip_pb_deserializing
  }
}

pub enum Default {
  /// Field must always be specified because it does not have a default.
  None,
  /// The default is given by `std::default::Default::default()`.
  Default,
  /// The default is given by this function.
  Path(syn::ExprPath),
}

pub fn is_recognizable_attribute(attr: &syn::Attribute) -> bool {
  attr.path == PB_ATTRS || attr.path == EVENT || attr.path == NODE_ATTRS || attr.path == NODES_ATTRS
}

pub fn get_pb_meta_items(
  cx: &ASTResult,
  attr: &syn::Attribute,
) -> Result<Vec<syn::NestedMeta>, ()> {
  // Only handle the attribute that we have defined
  if attr.path != PB_ATTRS {
    return Ok(vec![]);
  }

  // http://strymon.systems.ethz.ch/typename/syn/enum.Meta.html
  match attr.parse_meta() {
    Ok(List(meta)) => Ok(meta.nested.into_iter().collect()),
    Ok(other) => {
      cx.error_spanned_by(other, "expected #[pb(...)]");
      Err(())
    },
    Err(err) => {
      cx.error_spanned_by(attr, "attribute must be str, e.g. #[pb(xx = \"xxx\")]");
      cx.syn_error(err);
      Err(())
    },
  }
}

pub fn get_node_meta_items(
  cx: &ASTResult,
  attr: &syn::Attribute,
) -> Result<Vec<syn::NestedMeta>, ()> {
  // Only handle the attribute that we have defined
  if attr.path != NODE_ATTRS && attr.path != NODES_ATTRS {
    return Ok(vec![]);
  }

  // http://strymon.systems.ethz.ch/typename/syn/enum.Meta.html
  match attr.parse_meta() {
    Ok(List(meta)) => Ok(meta.nested.into_iter().collect()),
    Ok(_) => Ok(vec![]),
    Err(err) => {
      cx.error_spanned_by(attr, "attribute must be str, e.g. #[node(xx = \"xxx\")]");
      cx.syn_error(err);
      Err(())
    },
  }
}

pub fn get_event_meta_items(
  cx: &ASTResult,
  attr: &syn::Attribute,
) -> Result<Vec<syn::NestedMeta>, ()> {
  // Only handle the attribute that we have defined
  if attr.path != EVENT {
    return Ok(vec![]);
  }

  // http://strymon.systems.ethz.ch/typename/syn/enum.Meta.html
  match attr.parse_meta() {
    Ok(List(meta)) => Ok(meta.nested.into_iter().collect()),
    Ok(other) => {
      cx.error_spanned_by(other, "expected #[event(...)]");
      Err(())
    },
    Err(err) => {
      cx.error_spanned_by(attr, "attribute must be str, e.g. #[event(xx = \"xxx\")]");
      cx.syn_error(err);
      Err(())
    },
  }
}

pub fn parse_lit_into_expr_path(
  ast_result: &ASTResult,
  attr_name: Symbol,
  lit: &syn::Lit,
) -> Result<syn::ExprPath, ()> {
  let string = get_lit_str(ast_result, attr_name, lit)?;
  parse_lit_str(string).map_err(|_| {
    ast_result.error_spanned_by(lit, format!("failed to parse path: {:?}", string.value()))
  })
}

fn get_lit_str<'a>(
  ast_result: &ASTResult,
  attr_name: Symbol,
  lit: &'a syn::Lit,
) -> Result<&'a syn::LitStr, ()> {
  if let syn::Lit::Str(lit) = lit {
    Ok(lit)
  } else {
    ast_result.error_spanned_by(
      lit,
      format!(
        "expected pb {} attribute to be a string: `{} = \"...\"`",
        attr_name, attr_name
      ),
    );
    Err(())
  }
}

fn parse_lit_into_ty(
  ast_result: &ASTResult,
  attr_name: Symbol,
  lit: &syn::Lit,
) -> Result<syn::Type, ()> {
  let string = get_lit_str(ast_result, attr_name, lit)?;

  parse_lit_str(string).map_err(|_| {
    ast_result.error_spanned_by(
      lit,
      format!("failed to parse type: {} = {:?}", attr_name, string.value()),
    )
  })
}

pub fn parse_lit_str<T>(s: &syn::LitStr) -> parse::Result<T>
where
  T: Parse,
{
  let tokens = spanned_tokens(s)?;
  syn::parse2(tokens)
}

fn spanned_tokens(s: &syn::LitStr) -> parse::Result<TokenStream> {
  let stream = syn::parse_str(&s.value())?;
  Ok(respan_token_stream(stream, s.span()))
}

fn respan_token_stream(stream: TokenStream, span: Span) -> TokenStream {
  stream
    .into_iter()
    .map(|token| respan_token_tree(token, span))
    .collect()
}

fn respan_token_tree(mut token: TokenTree, span: Span) -> TokenTree {
  if let TokenTree::Group(g) = &mut token {
    *g = Group::new(g.delimiter(), respan_token_stream(g.stream(), span));
  }
  token.set_span(span);
  token
}

fn default_pb_type(ast_result: &ASTResult, ident: &syn::Ident) -> syn::Type {
  let take_ident = ident.to_string();
  let lit_str = syn::LitStr::new(&take_ident, ident.span());
  if let Ok(tokens) = spanned_tokens(&lit_str) {
    if let Ok(pb_struct_ty) = syn::parse2(tokens) {
      return pb_struct_ty;
    }
  }
  ast_result.error_spanned_by(
    ident,
    format!("❌ Can't find {} protobuf struct", take_ident),
  );
  panic!()
}

#[allow(dead_code)]
pub fn is_option(ty: &syn::Type) -> bool {
  let path = match ungroup(ty) {
    syn::Type::Path(ty) => &ty.path,
    _ => {
      return false;
    },
  };
  let seg = match path.segments.last() {
    Some(seg) => seg,
    None => {
      return false;
    },
  };
  let args = match &seg.arguments {
    syn::PathArguments::AngleBracketed(bracketed) => &bracketed.args,
    _ => {
      return false;
    },
  };
  seg.ident == "Option" && args.len() == 1
}

#[allow(dead_code)]
pub fn ungroup(mut ty: &syn::Type) -> &syn::Type {
  while let syn::Type::Group(group) = ty {
    ty = &group.elem;
  }
  ty
}

struct BoolAttr<'c>(ASTAttr<'c, ()>);

impl<'c> BoolAttr<'c> {
  fn none(ast_result: &'c ASTResult, name: Symbol) -> Self {
    BoolAttr(ASTAttr::none(ast_result, name))
  }

  fn set_true<A: ToTokens>(&mut self, obj: A) {
    self.0.set(obj, ());
  }

  fn get(&self) -> bool {
    self.0.value.is_some()
  }
}
