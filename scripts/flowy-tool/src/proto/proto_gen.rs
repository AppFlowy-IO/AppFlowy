use crate::proto::ast::*;
use crate::proto::helper::*;
use crate::{proto::template::*, util::*};
use flowy_ast::*;
use std::{fs::OpenOptions, io::Write};
use syn::Item;
use walkdir::WalkDir;

pub struct ProtoGen {
    rust_source_dir: Option<String>,
    proto_file_output_dir: Option<String>,
    rust_mod_dir: Option<String>,
    flutter_mod_dir: Option<String>,
    build_cache_dir: Option<String>,
}

impl ProtoGen {
    pub fn new() -> Self {
        ProtoGen {
            rust_source_dir: None,
            proto_file_output_dir: None,
            rust_mod_dir: None,
            flutter_mod_dir: None,
            build_cache_dir: None,
        }
    }

    pub fn set_rust_source_dir(mut self, dir: &str) -> Self {
        self.rust_source_dir = Some(dir.to_string());
        self
    }

    pub fn set_proto_file_output_dir(mut self, dir: &str) -> Self {
        self.proto_file_output_dir = Some(dir.to_string());
        self
    }

    pub fn set_rust_mod_dir(mut self, dir: &str) -> Self {
        self.rust_mod_dir = Some(dir.to_string());
        self
    }

    pub fn set_flutter_mod_dir(mut self, dir: &str) -> Self {
        self.flutter_mod_dir = Some(dir.to_string());
        self
    }

    pub fn set_build_cache_dir(mut self, build_cache_dir: &str) -> Self {
        self.build_cache_dir = Some(build_cache_dir.to_string());
        self
    }

    pub fn gen(&self) {
        let infos = parse_crate_protobuf(
            self.rust_source_dir.as_ref().unwrap().as_ref(),
            self.proto_file_output_dir.as_ref().unwrap().as_ref(),
        );
        self.write_proto_files(&infos);
        self.gen_derive(&infos);
        self.update_rust_flowy_protobuf_mod_file(&infos);
    }

    fn gen_derive(&self, crate_infos: &Vec<CrateProtoInfo>) {
        let file_proto_infos = crate_infos
            .iter()
            .map(|ref crate_info| &crate_info.files)
            .flatten()
            .collect::<Vec<&FileProtoInfo>>();

        let structs: Vec<String> = file_proto_infos
            .iter()
            .map(|info| info.structs.clone())
            .flatten()
            .collect();
        let enums: Vec<String> = file_proto_infos
            .iter()
            .map(|info| info.enums.clone())
            .flatten()
            .collect();
        let derive_file = self.build_cache_dir.as_ref().unwrap().clone();

        let mut derive_template = ProtobufDeriveCache::new(structs, enums);
        let new_content = derive_template.render().unwrap();
        let old_content = read_file(derive_file.as_ref()).unwrap();
        if new_content.clone() == old_content {
            return;
        }
        // println!("{}", diff_lines(&old_content, &new_content));
        match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&derive_file)
        {
            Ok(ref mut file) => {
                file.write_all(new_content.as_bytes()).unwrap();
            }
            Err(err) => {
                panic!("Failed to open log file: {}", err);
            }
        }
    }

    fn write_proto_files(&self, crate_infos: &Vec<CrateProtoInfo>) {
        for crate_info in crate_infos {
            crate_info.files.iter().for_each(|info| {
                // let dir = format!(
                //     "{}/{}",
                //     self.proto_file_output_dir.as_ref().unwrap(),
                //     &crate_info.name,
                // );
                let dir = format!("{}", self.proto_file_output_dir.as_ref().unwrap(),);

                if !std::path::Path::new(&dir).exists() {
                    std::fs::create_dir_all(&dir).unwrap();
                }

                let proto_file_path = format!("{}/{}.proto", dir, &info.file_name);
                let new_content = info.generated_content.clone();
                save_content_to_file_with_diff_prompt(
                    &new_content,
                    proto_file_path.as_ref(),
                    false,
                );
            });
        }
    }

    fn update_rust_flowy_protobuf_mod_file(&self, crate_infos: &Vec<CrateProtoInfo>) {
        for crate_info in crate_infos {
            // let dir = format!(
            //     "{}/{}-pb",
            //     self.rust_mod_dir.as_ref().unwrap(),
            //     &crate_info.name,
            // );

            let dir = format!("{}/model", self.rust_mod_dir.as_ref().unwrap(),);
            if !std::path::Path::new(&dir).exists() {
                std::fs::create_dir_all(&dir).unwrap();
            }
            let mod_path = format!("{}/mod.rs", dir);

            match OpenOptions::new()
                .create(false)
                .write(true)
                .append(false)
                .truncate(true)
                .open(&mod_path)
            {
                Ok(ref mut file) => {
                    let mut mod_file_content = String::new();
                    for (_, file_name) in
                        WalkDir::new(self.proto_file_output_dir.as_ref().unwrap().clone())
                            .into_iter()
                            .filter_map(|e| e.ok())
                            .filter(|e| e.file_type().is_dir() == false)
                            .map(|e| {
                                (
                                    e.path().to_str().unwrap().to_string(),
                                    e.path().file_stem().unwrap().to_str().unwrap().to_string(),
                                )
                            })
                    {
                        let c = format!("\nmod {}; \npub use {}::*; \n", &file_name, &file_name);
                        mod_file_content.push_str(c.as_ref());
                    }
                    file.write_all(mod_file_content.as_bytes()).unwrap();
                }
                Err(err) => {
                    panic!("Failed to open file: {}", err);
                }
            }
        }
    }
}
