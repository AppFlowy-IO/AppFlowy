use flowy_ast::{ASTContainer, ASTField, ASTResult};
use proc_macro2::TokenStream;

pub fn expand_derive(input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
    let ast_result = ASTResult::new();
    let cont = match ASTContainer::from_ast(&ast_result, input) {
        Some(cont) => cont,
        None => return Err(ast_result.check().unwrap_err()),
    };

    let mut token_stream: TokenStream = TokenStream::default();
    token_stream.extend(make_to_node_data_token_stream(&cont));

    if let Some(get_value_token_stream) = make_get_set_value_token_steam(&cont) {
        token_stream.extend(get_value_token_stream);
    }

    ast_result.check()?;
    Ok(token_stream)
}

pub fn make_alter_children_token_stream(ast: &ASTContainer) -> TokenStream {
    let mut token_streams = TokenStream::default();

    token_streams
}

pub fn make_to_node_data_token_stream(ast: &ASTContainer) -> TokenStream {
    let struct_ident = &ast.ident;
    let mut token_streams = TokenStream::default();
    let node_type = ast
        .node_type
        .as_ref()
        .expect("Define the type of the node by using #[node_type = \"xx\" in the struct");
    let set_key_values = ast
        .data
        .all_fields()
        .filter(|field| !field.node_attrs.is_children)
        .flat_map(|field| {
            let mut field_name = field.name().expect("the name of the field should not be empty");
            let original_field_name = field.name().expect("the name of the field should not be empty");
            if let Some(rename) = &field.node_attrs.rename {
                field_name = format_ident!("{}", rename.value());
            }
            let field_name_str = field_name.to_string();
            quote! {
               .insert_attribute(#field_name_str, self.#original_field_name.clone())
            }
        });

    let children_fields = ast
        .data
        .all_fields()
        .filter(|field| field.node_attrs.is_children)
        .collect::<Vec<&ASTField>>();

    let childrens_token_streams = match children_fields.is_empty() {
        true => {
            quote! {
                let children = vec![];
            }
        }
        false => {
            let children_field = children_fields.first().unwrap();
            let original_field_name = children_field
                .name()
                .expect("the name of the field should not be empty");
            quote! {
                let children = self.#original_field_name.iter().map(|value| value.to_node_data()).collect::<Vec<NodeData>>();
            }
        }
    };

    token_streams.extend(quote! {
      impl #struct_ident {
            pub fn to_node_data(&self) -> NodeData {
                #childrens_token_streams

                let builder = NodeDataBuilder::new(#node_type)
                #(#set_key_values)*
                .extend_node_data(children);

                builder.build()
            }
        }
    });

    token_streams
}

pub fn make_get_set_value_token_steam(ast: &ASTContainer) -> Option<TokenStream> {
    let struct_ident = &ast.ident;
    let mut token_streams = TokenStream::default();

    let tree = format_ident!("tree");
    for field in ast.data.all_fields() {
        if field.node_attrs.is_children {
            continue;
        }

        let mut field_name = field.name().expect("the name of the field should not be empty");
        if let Some(rename) = &field.node_attrs.rename {
            field_name = format_ident!("{}", rename.value());
        }

        let field_name_str = field_name.to_string();
        let get_func_name = format_ident!("get_{}", field_name);
        let set_func_name = format_ident!("set_{}", field_name);
        let get_value_return_ty = field.ty;
        let set_value_input_ty = field.ty;

        if let Some(get_value_with_fn) = field.node_attrs.get_node_value_with() {
            token_streams.extend(quote! {
              impl #struct_ident {
                    pub fn #get_func_name(&self) -> Option<#get_value_return_ty> {
                        #get_value_with_fn(self.#tree.clone(), &self.path, #field_name_str)
                    }
                }
            });
        }

        if let Some(set_value_with_fn) = field.node_attrs.set_node_value_with() {
            token_streams.extend(quote! {
              impl #struct_ident {
                    pub fn #set_func_name(&self, value: #set_value_input_ty) {
                        let _ = #set_value_with_fn(self.#tree.clone(), &self.path, #field_name_str, value);
                    }
                }
            });
        }
    }
    ast.data.all_fields().for_each(|field| {});
    Some(token_streams)
}
