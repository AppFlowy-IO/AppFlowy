use crate::{get_node_meta_items, parse_lit_into_expr_path, symbol::*, ASTAttr, ASTResult};
use quote::ToTokens;
use syn::{
  self, LitStr,
  Meta::NameValue,
  NestedMeta::{Lit, Meta},
};

pub struct NodeStructAttrs {
  pub rename: Option<LitStr>,
  pub has_child: bool,
  pub child_name: Option<LitStr>,
  pub child_index: Option<syn::LitInt>,
  pub get_node_value_with: Option<syn::ExprPath>,
  pub set_node_value_with: Option<syn::ExprPath>,
  pub with_children: Option<syn::ExprPath>,
}

impl NodeStructAttrs {
  /// Extract out the `#[node(...)]` attributes from a struct field.
  pub fn from_ast(ast_result: &ASTResult, _index: usize, field: &syn::Field) -> Self {
    let mut rename = ASTAttr::none(ast_result, RENAME_NODE);
    let mut child_name = ASTAttr::none(ast_result, CHILD_NODE_NAME);
    let mut child_index = ASTAttr::none(ast_result, CHILD_NODE_INDEX);
    let mut get_node_value_with = ASTAttr::none(ast_result, GET_NODE_VALUE_WITH);
    let mut set_node_value_with = ASTAttr::none(ast_result, SET_NODE_VALUE_WITH);
    let mut with_children = ASTAttr::none(ast_result, WITH_CHILDREN);

    for meta_item in field
      .attrs
      .iter()
      .flat_map(|attr| get_node_meta_items(ast_result, attr))
      .flatten()
    {
      match &meta_item {
        // Parse '#[node(rename = x)]'
        Meta(NameValue(m)) if m.path == RENAME_NODE => {
          if let syn::Lit::Str(lit) = &m.lit {
            rename.set(&m.path, lit.clone());
          }
        },

        // Parse '#[node(child_name = x)]'
        Meta(NameValue(m)) if m.path == CHILD_NODE_NAME => {
          if let syn::Lit::Str(lit) = &m.lit {
            child_name.set(&m.path, lit.clone());
          }
        },

        // Parse '#[node(child_index = x)]'
        Meta(NameValue(m)) if m.path == CHILD_NODE_INDEX => {
          if let syn::Lit::Int(lit) = &m.lit {
            child_index.set(&m.path, lit.clone());
          }
        },

        // Parse `#[node(get_node_value_with = "...")]`
        Meta(NameValue(m)) if m.path == GET_NODE_VALUE_WITH => {
          if let Ok(path) = parse_lit_into_expr_path(ast_result, GET_NODE_VALUE_WITH, &m.lit) {
            get_node_value_with.set(&m.path, path);
          }
        },

        // Parse `#[node(set_node_value_with= "...")]`
        Meta(NameValue(m)) if m.path == SET_NODE_VALUE_WITH => {
          if let Ok(path) = parse_lit_into_expr_path(ast_result, SET_NODE_VALUE_WITH, &m.lit) {
            set_node_value_with.set(&m.path, path);
          }
        },

        // Parse `#[node(with_children= "...")]`
        Meta(NameValue(m)) if m.path == WITH_CHILDREN => {
          if let Ok(path) = parse_lit_into_expr_path(ast_result, WITH_CHILDREN, &m.lit) {
            with_children.set(&m.path, path);
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
            format!("unknown node field attribute `{}`", path),
          );
        },

        Lit(lit) => {
          ast_result.error_spanned_by(lit, "unexpected literal in field attribute");
        },
      }
    }
    let child_name = child_name.get();
    NodeStructAttrs {
      rename: rename.get(),
      child_index: child_index.get(),
      has_child: child_name.is_some(),
      child_name,
      get_node_value_with: get_node_value_with.get(),
      set_node_value_with: set_node_value_with.get(),
      with_children: with_children.get(),
    }
  }
}
