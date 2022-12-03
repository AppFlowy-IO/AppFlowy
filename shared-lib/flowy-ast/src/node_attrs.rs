use crate::{get_node_meta_items, get_pb_meta_items, parse_lit_into_expr_path, symbol::*, ASTAttr, ASTResult};
use proc_macro2::{Group, Ident, Span, TokenStream, TokenTree};
use quote::ToTokens;
use syn::{
    self,
    parse::{self, Parse},
    LitStr,
    Meta::{List, NameValue, Path},
    NestedMeta::{Lit, Meta},
};

pub struct NodeStructAttrs {
    pub rename: Option<LitStr>,
    pub is_children: bool,
    node_index: Option<syn::LitInt>,
    get_node_value_with: Option<syn::ExprPath>,
    set_node_value_with: Option<syn::ExprPath>,
}

impl NodeStructAttrs {
    /// Extract out the `#[node(...)]` attributes from a struct field.
    pub fn from_ast(ast_result: &ASTResult, index: usize, field: &syn::Field) -> Self {
        let mut node_index = ASTAttr::none(ast_result, NODE_INDEX);
        let mut rename = ASTAttr::none(ast_result, NODE_RENAME);
        let mut is_children = ASTAttr::none(ast_result, NODE_CHILDREN);
        let mut get_node_value_with = ASTAttr::none(ast_result, GET_NODE_VALUE_WITH);
        let mut set_node_value_with = ASTAttr::none(ast_result, SET_NODE_VALUE_WITH);

        for meta_item in field
            .attrs
            .iter()
            .flat_map(|attr| get_node_meta_items(ast_result, attr))
            .flatten()
        {
            match &meta_item {
                // Parse '#[node(index = x)]'
                Meta(NameValue(m)) if m.path == NODE_INDEX => {
                    if let syn::Lit::Int(lit) = &m.lit {
                        node_index.set(&m.path, lit.clone());
                    }
                }

                // Parse '#[node(children)]'
                Meta(Path(path)) if path == NODE_CHILDREN => {
                    eprintln!("😄 {:?}", path);
                    is_children.set(path, true);
                }

                // Parse '#[node(rename = x)]'
                Meta(NameValue(m)) if m.path == NODE_RENAME => {
                    if let syn::Lit::Str(lit) = &m.lit {
                        rename.set(&m.path, lit.clone());
                    }
                }
                // Parse `#[node(get_node_value_with = "...")]`
                Meta(NameValue(m)) if m.path == GET_NODE_VALUE_WITH => {
                    if let Ok(path) = parse_lit_into_expr_path(ast_result, GET_NODE_VALUE_WITH, &m.lit) {
                        get_node_value_with.set(&m.path, path);
                    }
                }

                // Parse `#[node(set_node_value_with= "...")]`
                Meta(NameValue(m)) if m.path == SET_NODE_VALUE_WITH => {
                    if let Ok(path) = parse_lit_into_expr_path(ast_result, SET_NODE_VALUE_WITH, &m.lit) {
                        set_node_value_with.set(&m.path, path);
                    }
                }

                Meta(meta_item) => {
                    let path = meta_item.path().into_token_stream().to_string().replace(' ', "");
                    ast_result.error_spanned_by(meta_item.path(), format!("unknown node field attribute `{}`", path));
                }

                Lit(lit) => {
                    ast_result.error_spanned_by(lit, "unexpected literal in field attribute");
                }
            }
        }

        NodeStructAttrs {
            rename: rename.get(),
            node_index: node_index.get(),
            is_children: is_children.get().unwrap_or(false),
            get_node_value_with: get_node_value_with.get(),
            set_node_value_with: set_node_value_with.get(),
        }
    }

    pub fn set_node_value_with(&self) -> Option<&syn::ExprPath> {
        self.set_node_value_with.as_ref()
    }

    pub fn get_node_value_with(&self) -> Option<&syn::ExprPath> {
        self.get_node_value_with.as_ref()
    }
}
