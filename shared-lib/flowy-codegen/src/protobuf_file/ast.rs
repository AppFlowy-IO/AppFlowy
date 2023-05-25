#![allow(unused_attributes)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_results)]
use crate::protobuf_file::template::{EnumTemplate, StructTemplate, RUST_TYPE_MAP};
use crate::protobuf_file::{parse_crate_info_from_path, ProtoFile, ProtobufCrateContext};
use crate::util::*;
use fancy_regex::Regex;
use flowy_ast::*;
use lazy_static::lazy_static;
use std::path::PathBuf;
use std::{fs::File, io::Read, path::Path};
use syn::Item;
use walkdir::WalkDir;

pub fn parse_protobuf_context_from(crate_paths: Vec<String>) -> Vec<ProtobufCrateContext> {
  let crate_infos = parse_crate_info_from_path(crate_paths);
  crate_infos
    .into_iter()
    .map(|crate_info| {
      let proto_output_path = crate_info.proto_output_path();
      let files = crate_info
        .proto_input_paths()
        .iter()
        .flat_map(|proto_crate_path| parse_files_protobuf(proto_crate_path, &proto_output_path))
        .collect::<Vec<ProtoFile>>();

      ProtobufCrateContext::from_crate_info(crate_info, files)
    })
    .collect::<Vec<ProtobufCrateContext>>()
}

fn parse_files_protobuf(proto_crate_path: &Path, proto_output_path: &Path) -> Vec<ProtoFile> {
  let mut gen_proto_vec: Vec<ProtoFile> = vec![];
  // file_stem https://doc.rust-lang.org/std/path/struct.Path.html#method.file_stem
  for (path, file_name) in WalkDir::new(proto_crate_path)
    .into_iter()
    .filter_entry(|e| !is_hidden(e))
    .filter_map(|e| e.ok())
    .filter(|e| !e.file_type().is_dir())
    .map(|e| {
      let path = e.path().to_str().unwrap().to_string();
      let file_name = e.path().file_stem().unwrap().to_str().unwrap().to_string();
      (path, file_name)
    })
  {
    if file_name == "mod" {
      continue;
    }

    // https://docs.rs/syn/1.0.54/syn/struct.File.html
    let ast = syn::parse_file(read_file(&path).unwrap().as_ref())
      .unwrap_or_else(|_| panic!("Unable to parse file at {}", path));
    let structs = get_ast_structs(&ast);
    let proto_file = format!("{}.proto", &file_name);
    let proto_file_path = path_string_with_component(proto_output_path, vec![&proto_file]);
    let proto_syntax = find_proto_syntax(proto_file_path.as_ref());

    let mut proto_content = String::new();

    // The types that are not defined in the current file.
    let mut ref_types: Vec<String> = vec![];
    structs.iter().for_each(|s| {
      let mut struct_template = StructTemplate::new();
      struct_template.set_message_struct_name(&s.name);

      s.fields
        .iter()
        .filter(|field| field.pb_attrs.pb_index().is_some())
        .for_each(|field| {
          ref_types.push(field.ty_as_str());
          struct_template.set_field(field);
        });

      let s = struct_template.render().unwrap();

      proto_content.push_str(s.as_ref());
      proto_content.push('\n');
    });

    let enums = get_ast_enums(&ast);
    enums.iter().for_each(|e| {
      let mut enum_template = EnumTemplate::new();
      enum_template.set_message_enum(e);
      let s = enum_template.render().unwrap();
      proto_content.push_str(s.as_ref());
      ref_types.push(e.name.clone());

      proto_content.push('\n');
    });

    if !enums.is_empty() || !structs.is_empty() {
      let structs: Vec<String> = structs.iter().map(|s| s.name.clone()).collect();
      let enums: Vec<String> = enums.iter().map(|e| e.name.clone()).collect();
      ref_types.retain(|s| !structs.contains(s));
      ref_types.retain(|s| !enums.contains(s));

      let info = ProtoFile {
        file_path: path.clone(),
        file_name: file_name.clone(),
        ref_types,
        structs,
        enums,
        syntax: proto_syntax,
        content: proto_content,
      };
      gen_proto_vec.push(info);
    }
  }

  gen_proto_vec
}

pub fn get_ast_structs(ast: &syn::File) -> Vec<Struct> {
  // let mut content = format!("{:#?}", &ast);
  // let mut file = File::create("./foo.txt").unwrap();
  // file.write_all(content.as_bytes()).unwrap();
  let ast_result = ASTResult::new();
  let mut proto_structs: Vec<Struct> = vec![];
  ast.items.iter().for_each(|item| {
    if let Item::Struct(item_struct) = item {
      let (_, fields) = struct_from_ast(&ast_result, &item_struct.fields);

      if fields
        .iter()
        .filter(|f| f.pb_attrs.pb_index().is_some())
        .count()
        > 0
      {
        proto_structs.push(Struct {
          name: item_struct.ident.to_string(),
          fields,
        });
      }
    }
  });
  ast_result.check().unwrap();
  proto_structs
}

pub fn get_ast_enums(ast: &syn::File) -> Vec<FlowyEnum> {
  let mut flowy_enums: Vec<FlowyEnum> = vec![];
  let ast_result = ASTResult::new();

  ast.items.iter().for_each(|item| {
    // https://docs.rs/syn/1.0.54/syn/enum.Item.html
    if let Item::Enum(item_enum) = item {
      let attrs = flowy_ast::enum_from_ast(
        &ast_result,
        &item_enum.ident,
        &item_enum.variants,
        &ast.attrs,
      );
      flowy_enums.push(FlowyEnum {
        name: item_enum.ident.to_string(),
        attrs,
      });
    }
  });
  ast_result.check().unwrap();
  flowy_enums
}

pub struct FlowyEnum<'a> {
  pub name: String,
  pub attrs: Vec<ASTEnumVariant<'a>>,
}

pub struct Struct<'a> {
  pub name: String,
  pub fields: Vec<ASTField<'a>>,
}

lazy_static! {
    static ref SYNTAX_REGEX: Regex = Regex::new("syntax.*;").unwrap();
    // static ref IMPORT_REGEX: Regex = Regex::new("(import\\s).*;").unwrap();
}

fn find_proto_syntax(path: &str) -> String {
  if !Path::new(path).exists() {
    return String::from("syntax = \"proto3\";\n");
  }

  let mut result = String::new();
  let mut file = File::open(path).unwrap();
  let mut content = String::new();
  file.read_to_string(&mut content).unwrap();

  content.lines().for_each(|line| {
    ////Result<Option<Match<'t>>>
    if let Ok(Some(m)) = SYNTAX_REGEX.find(line) {
      result.push_str(m.as_str());
    }

    // if let Ok(Some(m)) = IMPORT_REGEX.find(line) {
    //     result.push_str(m.as_str());
    //     result.push('\n');
    // }
  });

  result.push('\n');
  result
}
