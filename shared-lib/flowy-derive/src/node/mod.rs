use flowy_ast::{ASTContainer, ASTField, ASTResult};
use proc_macro2::TokenStream;

pub fn expand_derive(input: &syn::DeriveInput) -> Result<TokenStream, Vec<syn::Error>> {
  let ast_result = ASTResult::new();
  let cont = match ASTContainer::from_ast(&ast_result, input) {
    Some(cont) => cont,
    None => return Err(ast_result.check().unwrap_err()),
  };

  let mut token_stream: TokenStream = TokenStream::default();
  token_stream.extend(make_helper_funcs_token_stream(&cont));
  token_stream.extend(make_to_node_data_token_stream(&cont));

  if let Some(get_value_token_stream) = make_get_set_value_token_steam(&cont) {
    token_stream.extend(get_value_token_stream);
  }

  token_stream.extend(make_alter_children_token_stream(&ast_result, &cont));
  ast_result.check()?;
  Ok(token_stream)
}

pub fn make_helper_funcs_token_stream(ast: &ASTContainer) -> TokenStream {
  let mut token_streams = TokenStream::default();
  let struct_ident = &ast.ident;
  token_streams.extend(quote! {
    impl #struct_ident {
          pub fn get_path(&self) -> Option<Path> {
              let node_id = &self.node_id?;
             Some(self.tree.read().path_from_node_id(node_id.clone()))
          }
      }
  });
  token_streams
}

pub fn make_alter_children_token_stream(ast_result: &ASTResult, ast: &ASTContainer) -> TokenStream {
  let mut token_streams = TokenStream::default();
  let children_fields = ast
    .data
    .all_fields()
    .filter(|field| field.node_attrs.has_child)
    .collect::<Vec<&ASTField>>();

  if !children_fields.is_empty() {
    let struct_ident = &ast.ident;
    if children_fields.len() > 1 {
      ast_result.error_spanned_by(struct_ident, "Only one children property");
      return token_streams;
    }
    let children_field = children_fields.first().unwrap();
    let field_name = children_field.name().unwrap();
    let child_name = children_field.node_attrs.child_name.as_ref().unwrap();
    let get_func_name = format_ident!("get_{}", child_name.value());
    let get_mut_func_name = format_ident!("get_mut_{}", child_name.value());
    let add_func_name = format_ident!("add_{}", child_name.value());
    let remove_func_name = format_ident!("remove_{}", child_name.value());
    let ty = children_field.bracket_inner_ty.as_ref().unwrap().clone();

    token_streams.extend(quote! {
             impl #struct_ident {
                pub fn #get_func_name<T: AsRef<str>>(&self, id: T) -> Option<&#ty> {
                    let id = id.as_ref();
                    self.#field_name.iter().find(|element| element.id == id)
                }

                pub fn #get_mut_func_name<T: AsRef<str>>(&mut self, id: T) -> Option<&mut #ty> {
                    let id = id.as_ref();
                    self.#field_name.iter_mut().find(|element| element.id == id)
                }

                pub fn #remove_func_name<T: AsRef<str>>(&mut self, id: T) {
                    let id = id.as_ref();
                     if let Some(index) = self.#field_name.iter().position(|element| element.id == id && element.node_id.is_some()) {
                        let element = self.#field_name.remove(index);
                        let element_path = element.get_path().unwrap();

                        let mut write_guard = self.tree.write();
                        let mut nodes = vec![];

                        if let Some(node_data) = element.node_id.and_then(|node_id| write_guard.get_node_data(node_id.clone())) {
                            nodes.push(node_data);
                        }
                        let _ = write_guard.apply_op(NodeOperation::Delete {
                            path: element_path,
                            nodes,
                        });
                    }
                }

                pub fn #add_func_name(&mut self, mut value: #ty) -> Result<(), String> {
                    if self.node_id.is_none() {
                        return Err("The node id is empty".to_owned());
                    }

                    let mut transaction = Transaction::new();
                    let parent_path = self.get_path().unwrap();

                    let path = parent_path.clone_with(self.#field_name.len());
                    let node_data = value.to_node_data();
                    transaction.push_operation(NodeOperation::Insert {
                        path: path.clone(),
                        nodes: vec![node_data],
                     });

                    let _ = self.tree.write().apply_transaction(transaction);
                    let child_node_id = self.tree.read().node_id_at_path(path).unwrap();
                    value.node_id = Some(child_node_id);
                    self.#field_name.push(value);
                    Ok(())
                }
             }
        });
  }

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
    .filter(|field| !field.node_attrs.has_child)
    .flat_map(|field| {
      let mut field_name = field
        .name()
        .expect("the name of the field should not be empty");
      let original_field_name = field
        .name()
        .expect("the name of the field should not be empty");
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
    .filter(|field| field.node_attrs.has_child)
    .collect::<Vec<&ASTField>>();

  let childrens_token_streams = match children_fields.is_empty() {
    true => {
      quote! {
          let children = vec![];
      }
    },
    false => {
      let children_field = children_fields.first().unwrap();
      let original_field_name = children_field
        .name()
        .expect("the name of the field should not be empty");
      quote! {
          let children = self.#original_field_name.iter().map(|value| value.to_node_data()).collect::<Vec<NodeData>>();
      }
    },
  };

  token_streams.extend(quote! {
    impl ToNodeData for #struct_ident {
          fn to_node_data(&self) -> NodeData {
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
    if field.node_attrs.has_child {
      continue;
    }

    let mut field_name = field
      .name()
      .expect("the name of the field should not be empty");
    if let Some(rename) = &field.node_attrs.rename {
      field_name = format_ident!("{}", rename.value());
    }

    let field_name_str = field_name.to_string();
    let get_func_name = format_ident!("get_{}", field_name);
    let set_func_name = format_ident!("set_{}", field_name);
    let get_value_return_ty = field.ty;
    let set_value_input_ty = field.ty;

    if let Some(get_value_with_fn) = &field.node_attrs.get_node_value_with {
      token_streams.extend(quote! {
        impl #struct_ident {
              pub fn #get_func_name(&self) -> Option<#get_value_return_ty> {
                  let node_id = self.node_id.as_ref()?;
                  #get_value_with_fn(self.#tree.clone(), node_id, #field_name_str)
              }
          }
      });
    }

    if let Some(set_value_with_fn) = &field.node_attrs.set_node_value_with {
      token_streams.extend(quote! {
              impl #struct_ident {
                    pub fn #set_func_name(&self, value: #set_value_input_ty) {
                        if let Some(node_id) = self.node_id.as_ref() {
                            let _ = #set_value_with_fn(self.#tree.clone(), node_id, #field_name_str, value);
                        }
                    }
                }
            });
    }
  }
  Some(token_streams)
}
