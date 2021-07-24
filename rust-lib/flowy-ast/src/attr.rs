use crate::{symbol::*, Ctxt};

use quote::ToTokens;
use syn::{
    self,
    parse::{self, Parse},
    Meta::{List, NameValue, Path},
    NestedMeta::{Lit, Meta},
};

use proc_macro2::{Group, Span, TokenStream, TokenTree};

#[allow(dead_code)]
pub struct AttrsContainer {
    name: String,
    pb_struct_type: Option<syn::Type>,
    pb_enum_type: Option<syn::Type>,
}

impl AttrsContainer {
    /// Extract out the `#[pb(...)]` attributes from an item.
    pub fn from_ast(cx: &Ctxt, item: &syn::DeriveInput) -> Self {
        let mut pb_struct_type = ASTAttr::none(cx, PB_STRUCT);
        let mut pb_enum_type = ASTAttr::none(cx, PB_ENUM);
        for meta_item in item
            .attrs
            .iter()
            .flat_map(|attr| get_meta_items(cx, attr))
            .flatten()
        {
            match &meta_item {
                // Parse `#[pb(struct = "Type")]
                Meta(NameValue(m)) if m.path == PB_STRUCT => {
                    if let Ok(into_ty) = parse_lit_into_ty(cx, PB_STRUCT, &m.lit) {
                        pb_struct_type.set_opt(&m.path, Some(into_ty));
                    }
                },

                // Parse `#[pb(enum = "Type")]
                Meta(NameValue(m)) if m.path == PB_ENUM => {
                    if let Ok(into_ty) = parse_lit_into_ty(cx, PB_ENUM, &m.lit) {
                        pb_enum_type.set_opt(&m.path, Some(into_ty));
                    }
                },

                Meta(meta_item) => {
                    let path = meta_item
                        .path()
                        .into_token_stream()
                        .to_string()
                        .replace(' ', "");
                    cx.error_spanned_by(
                        meta_item.path(),
                        format!("unknown pb container attribute `{}`", path),
                    );
                },

                Lit(lit) => {
                    cx.error_spanned_by(lit, "unexpected literal in pb container attribute");
                },
            }
        }
        match &item.data {
            syn::Data::Struct(_) => {
                pb_struct_type.set_if_none(default_pb_type(&cx, &item.ident));
            },
            syn::Data::Enum(_) => {
                pb_enum_type.set_if_none(default_pb_type(&cx, &item.ident));
            },
            _ => {},
        }

        AttrsContainer {
            name: item.ident.to_string(),
            pb_struct_type: pb_struct_type.get(),
            pb_enum_type: pb_enum_type.get(),
        }
    }

    pub fn pb_struct_type(&self) -> Option<&syn::Type> { self.pb_struct_type.as_ref() }

    pub fn pb_enum_type(&self) -> Option<&syn::Type> { self.pb_enum_type.as_ref() }
}

struct ASTAttr<'c, T> {
    cx: &'c Ctxt,
    name: Symbol,
    tokens: TokenStream,
    value: Option<T>,
}

impl<'c, T> ASTAttr<'c, T> {
    fn none(cx: &'c Ctxt, name: Symbol) -> Self {
        ASTAttr {
            cx,
            name,
            tokens: TokenStream::new(),
            value: None,
        }
    }

    fn set<A: ToTokens>(&mut self, obj: A, value: T) {
        let tokens = obj.into_token_stream();

        if self.value.is_some() {
            self.cx
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

    fn set_if_none(&mut self, value: T) {
        if self.value.is_none() {
            self.value = Some(value);
        }
    }

    fn get(self) -> Option<T> { self.value }

    #[allow(dead_code)]
    fn get_with_tokens(self) -> Option<(TokenStream, T)> {
        match self.value {
            Some(v) => Some((self.tokens, v)),
            None => None,
        }
    }
}

pub struct ASTAttrField {
    #[allow(dead_code)]
    name: String,
    pb_index: Option<syn::LitInt>,
    pb_one_of: bool,
    skip_serializing: bool,
    skip_deserializing: bool,
    serialize_with: Option<syn::ExprPath>,
    deserialize_with: Option<syn::ExprPath>,
}

impl ASTAttrField {
    /// Extract out the `#[pb(...)]` attributes from a struct field.
    pub fn from_ast(cx: &Ctxt, index: usize, field: &syn::Field) -> Self {
        let mut pb_index = ASTAttr::none(cx, PB_INDEX);
        let mut pb_one_of = BoolAttr::none(cx, PB_ONE_OF);
        let mut serialize_with = ASTAttr::none(cx, SERIALIZE_WITH);
        let mut skip_serializing = BoolAttr::none(cx, SKIP_SERIALIZING);
        let mut deserialize_with = ASTAttr::none(cx, DESERIALIZE_WITH);
        let mut skip_deserializing = BoolAttr::none(cx, SKIP_DESERIALIZING);

        let ident = match &field.ident {
            Some(ident) => ident.to_string(),
            None => index.to_string(),
        };

        for meta_item in field
            .attrs
            .iter()
            .flat_map(|attr| get_meta_items(cx, attr))
            .flatten()
        {
            match &meta_item {
                // Parse `#[pb(skip)]`
                Meta(Path(word)) if word == SKIP => {
                    skip_serializing.set_true(word);
                    skip_deserializing.set_true(word);
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

                // Parse `#[pb(serialize_with = "...")]`
                Meta(NameValue(m)) if m.path == SERIALIZE_WITH => {
                    if let Ok(path) = parse_lit_into_expr_path(cx, SERIALIZE_WITH, &m.lit) {
                        serialize_with.set(&m.path, path);
                    }
                },

                // Parse `#[pb(deserialize_with = "...")]`
                Meta(NameValue(m)) if m.path == DESERIALIZE_WITH => {
                    if let Ok(path) = parse_lit_into_expr_path(cx, DESERIALIZE_WITH, &m.lit) {
                        deserialize_with.set(&m.path, path);
                    }
                },

                Meta(meta_item) => {
                    let path = meta_item
                        .path()
                        .into_token_stream()
                        .to_string()
                        .replace(' ', "");
                    cx.error_spanned_by(
                        meta_item.path(),
                        format!("unknown field attribute `{}`", path),
                    );
                },

                Lit(lit) => {
                    cx.error_spanned_by(lit, "unexpected literal in pb field attribute");
                },
            }
        }

        ASTAttrField {
            name: ident.to_string().clone(),
            pb_index: pb_index.get(),
            pb_one_of: pb_one_of.get(),
            skip_serializing: skip_serializing.get(),
            skip_deserializing: skip_deserializing.get(),
            serialize_with: serialize_with.get(),
            deserialize_with: deserialize_with.get(),
        }
    }

    #[allow(dead_code)]
    pub fn pb_index(&self) -> Option<String> {
        match self.pb_index {
            Some(ref lit) => Some(lit.base10_digits().to_string()),
            None => None,
        }
    }

    pub fn is_one_of(&self) -> bool { self.pb_one_of }

    pub fn serialize_with(&self) -> Option<&syn::ExprPath> { self.serialize_with.as_ref() }

    pub fn deserialize_with(&self) -> Option<&syn::ExprPath> { self.deserialize_with.as_ref() }

    pub fn skip_serializing(&self) -> bool { self.skip_serializing }

    pub fn skip_deserializing(&self) -> bool { self.skip_deserializing }
}

pub enum Default {
    /// Field must always be specified because it does not have a default.
    None,
    /// The default is given by `std::default::Default::default()`.
    Default,
    /// The default is given by this function.
    Path(syn::ExprPath),
}

#[derive(Debug, Clone)]
pub struct EventAttrs {
    input: Option<syn::Path>,
    output: Option<syn::Path>,
    error_ty: Option<String>,
    pub ignore: bool,
}

#[derive(Debug, Clone)]
pub struct ASTEnumAttrVariant {
    pub enum_name: String,
    pub enum_item_name: String,
    pub value: String,
    pub event_attrs: EventAttrs,
}

impl ASTEnumAttrVariant {
    pub fn from_ast(
        ctxt: &Ctxt,
        ident: &syn::Ident,
        variant: &syn::Variant,
        enum_attrs: &Vec<syn::Attribute>,
    ) -> Self {
        let enum_item_name = variant.ident.to_string();
        let enum_name = ident.to_string();
        let mut value = String::new();
        if variant.discriminant.is_some() {
            match variant.discriminant.as_ref().unwrap().1 {
                syn::Expr::Lit(ref expr_list) => {
                    let lit_int = if let syn::Lit::Int(ref int_value) = expr_list.lit {
                        int_value
                    } else {
                        unimplemented!()
                    };
                    value = lit_int.base10_digits().to_string();
                },
                _ => {},
            }
        }
        let event_attrs = get_event_attrs_from(ctxt, &variant.attrs, enum_attrs);
        ASTEnumAttrVariant {
            enum_name,
            enum_item_name,
            value,
            event_attrs,
        }
    }

    pub fn event_input(&self) -> Option<syn::Path> { self.event_attrs.input.clone() }

    pub fn event_output(&self) -> Option<syn::Path> { self.event_attrs.output.clone() }

    pub fn event_error(&self) -> String { self.event_attrs.error_ty.as_ref().unwrap().clone() }
}

fn get_event_attrs_from(
    ctxt: &Ctxt,
    variant_attrs: &Vec<syn::Attribute>,
    enum_attrs: &Vec<syn::Attribute>,
) -> EventAttrs {
    let mut event_attrs = EventAttrs {
        input: None,
        output: None,
        error_ty: None,
        ignore: false,
    };

    enum_attrs
        .iter()
        .filter(|attr| {
            attr.path
                .segments
                .iter()
                .find(|s| s.ident == EVENT_ERR)
                .is_some()
        })
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

    let mut extract_event_attr =
        |attr: &syn::Attribute, meta_item: &syn::NestedMeta| match &meta_item {
            Meta(NameValue(name_value)) => {
                if name_value.path == EVENT_INPUT {
                    if let syn::Lit::Str(s) = &name_value.lit {
                        let input_type = parse_lit_str(s)
                            .map_err(|_| {
                                ctxt.error_spanned_by(
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
                                ctxt.error_spanned_by(
                                    s,
                                    format!(
                                        "failed to parse response deserializer {:?}",
                                        s.value()
                                    ),
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
            Lit(s) => ctxt.error_spanned_by(s, "unexpected attribute"),
            _ => ctxt.error_spanned_by(meta_item, "unexpected attribute"),
        };

    let attr_meta_items_info = variant_attrs
        .iter()
        .flat_map(|attr| match get_meta_items(ctxt, attr) {
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

pub fn get_meta_items(cx: &Ctxt, attr: &syn::Attribute) -> Result<Vec<syn::NestedMeta>, ()> {
    if attr.path != PB_ATTRS && attr.path != EVENT {
        return Ok(Vec::new());
    }

    // http://strymon.systems.ethz.ch/typename/syn/enum.Meta.html
    match attr.parse_meta() {
        Ok(List(meta)) => Ok(meta.nested.into_iter().collect()),
        Ok(other) => {
            cx.error_spanned_by(other, "expected #[pb(...)] or or #[event(...)]");
            Err(())
        },
        Err(err) => {
            cx.error_spanned_by(attr, "attribute must be str, e.g. #[pb(xx = \"xxx\")]");
            cx.syn_error(err);
            Err(())
        },
    }
}

fn parse_lit_into_expr_path(
    cx: &Ctxt,
    attr_name: Symbol,
    lit: &syn::Lit,
) -> Result<syn::ExprPath, ()> {
    let string = get_lit_str(cx, attr_name, lit)?;
    parse_lit_str(string).map_err(|_| {
        cx.error_spanned_by(lit, format!("failed to parse path: {:?}", string.value()))
    })
}

fn get_lit_str<'a>(cx: &Ctxt, attr_name: Symbol, lit: &'a syn::Lit) -> Result<&'a syn::LitStr, ()> {
    if let syn::Lit::Str(lit) = lit {
        Ok(lit)
    } else {
        cx.error_spanned_by(
            lit,
            format!(
                "expected pb {} attribute to be a string: `{} = \"...\"`",
                attr_name, attr_name
            ),
        );
        Err(())
    }
}

fn parse_lit_into_ty(cx: &Ctxt, attr_name: Symbol, lit: &syn::Lit) -> Result<syn::Type, ()> {
    let string = get_lit_str(cx, attr_name, lit)?;

    parse_lit_str(string).map_err(|_| {
        cx.error_spanned_by(
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

fn default_pb_type(ctxt: &Ctxt, ident: &syn::Ident) -> syn::Type {
    let take_ident = format!("{}", ident.to_string());
    let lit_str = syn::LitStr::new(&take_ident, ident.span());
    if let Ok(tokens) = spanned_tokens(&lit_str) {
        if let Ok(pb_struct_ty) = syn::parse2(tokens) {
            return pb_struct_ty;
        }
    }
    ctxt.error_spanned_by(
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
    fn none(cx: &'c Ctxt, name: Symbol) -> Self { BoolAttr(ASTAttr::none(cx, name)) }

    fn set_true<A: ToTokens>(&mut self, obj: A) { self.0.set(obj, ()); }

    fn get(&self) -> bool { self.0.value.is_some() }
}
