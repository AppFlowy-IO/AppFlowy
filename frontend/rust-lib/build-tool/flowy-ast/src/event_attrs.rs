use crate::{get_event_meta_items, parse_lit_str, symbol::*, ASTResult};

use syn::{
  self,
  Meta::{NameValue, Path},
  NestedMeta::{Lit, Meta},
};

#[derive(Debug, Clone)]
pub struct EventAttrs {
  input: Option<syn::Path>,
  output: Option<syn::Path>,
  error_ty: Option<String>,
  pub ignore: bool,
}

#[derive(Debug, Clone)]
pub struct EventEnumAttrs {
  pub enum_name: String,
  pub enum_item_name: String,
  pub value: String,
  pub event_attrs: EventAttrs,
}

impl EventEnumAttrs {
  pub fn from_ast(
    ast_result: &ASTResult,
    ident: &syn::Ident,
    variant: &syn::Variant,
    enum_attrs: &[syn::Attribute],
  ) -> Self {
    let enum_item_name = variant.ident.to_string();
    let enum_name = ident.to_string();
    let mut value = String::new();
    if variant.discriminant.is_some() {
      if let syn::Expr::Lit(ref expr_list) = variant.discriminant.as_ref().unwrap().1 {
        let lit_int = if let syn::Lit::Int(ref int_value) = expr_list.lit {
          int_value
        } else {
          unimplemented!()
        };
        value = lit_int.base10_digits().to_string();
      }
    }
    let event_attrs = get_event_attrs_from(ast_result, &variant.attrs, enum_attrs);
    EventEnumAttrs {
      enum_name,
      enum_item_name,
      value,
      event_attrs,
    }
  }

  pub fn event_input(&self) -> Option<syn::Path> {
    self.event_attrs.input.clone()
  }

  pub fn event_output(&self) -> Option<syn::Path> {
    self.event_attrs.output.clone()
  }

  pub fn event_error(&self) -> String {
    self.event_attrs.error_ty.as_ref().unwrap().clone()
  }
}

fn get_event_attrs_from(
  ast_result: &ASTResult,
  variant_attrs: &[syn::Attribute],
  enum_attrs: &[syn::Attribute],
) -> EventAttrs {
  let mut event_attrs = EventAttrs {
    input: None,
    output: None,
    error_ty: None,
    ignore: false,
  };

  enum_attrs
    .iter()
    .filter(|attr| attr.path.segments.iter().any(|s| s.ident == EVENT_ERR))
    .for_each(|attr| {
      if let Ok(NameValue(named_value)) = attr.parse_meta() {
        if let syn::Lit::Str(s) = named_value.lit {
          event_attrs.error_ty = Some(s.value());
        } else {
          eprintln!("❌ {} should not be empty", EVENT_ERR);
        }
      } else {
        eprintln!("❌ Can not find any {} on attr: {:#?}", EVENT_ERR, attr);
      }
    });

  let mut extract_event_attr = |attr: &syn::Attribute, meta_item: &syn::NestedMeta| match &meta_item
  {
    Meta(NameValue(name_value)) => {
      if name_value.path == EVENT_INPUT {
        if let syn::Lit::Str(s) = &name_value.lit {
          let input_type = parse_lit_str(s)
            .map_err(|_| {
              ast_result.error_spanned_by(
                s,
                format!("failed to parse request deserializer {:?}", s.value()),
              )
            })
            .unwrap();
          event_attrs.input = Some(input_type);
        }
      }

      if name_value.path == EVENT_OUTPUT {
        if let syn::Lit::Str(s) = &name_value.lit {
          let output_type = parse_lit_str(s)
            .map_err(|_| {
              ast_result.error_spanned_by(
                s,
                format!("failed to parse response deserializer {:?}", s.value()),
              )
            })
            .unwrap();
          event_attrs.output = Some(output_type);
        }
      }
    },
    Meta(Path(word)) => {
      if word == EVENT_IGNORE && attr.path == EVENT {
        event_attrs.ignore = true;
      }
    },
    Lit(s) => ast_result.error_spanned_by(s, "unexpected attribute"),
    _ => ast_result.error_spanned_by(meta_item, "unexpected attribute"),
  };

  let attr_meta_items_info = variant_attrs
    .iter()
    .flat_map(|attr| match get_event_meta_items(ast_result, attr) {
      Ok(items) => Some((attr, items)),
      Err(_) => None,
    })
    .collect::<Vec<(&syn::Attribute, Vec<syn::NestedMeta>)>>();

  for (attr, nested_metas) in attr_meta_items_info {
    nested_metas
      .iter()
      .for_each(|meta_item| extract_event_attr(attr, meta_item))
  }

  // eprintln!("😁{:#?}", event_attrs);
  event_attrs
}
