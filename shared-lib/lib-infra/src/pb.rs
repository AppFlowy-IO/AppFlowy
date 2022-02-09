#![allow(clippy::all)]
#![allow(unused_imports)]
#![allow(unused_attributes)]
#![allow(dead_code)]
use crate::proto_gen;
use crate::proto_gen::proto_info::ProtobufCrate;
use crate::proto_gen::util::suffix_relative_to_path;
use crate::proto_gen::ProtoGenerator;
use log::info;
use std::fs::File;
use std::io::Write;
use std::process::Command;
use walkdir::WalkDir;

fn gen_protos(root: &str) -> Vec<ProtobufCrate> {
    let crate_context = ProtoGenerator::gen(root);
    let proto_crates = crate_context
        .iter()
        .map(|info| info.protobuf_crate.clone())
        .collect::<Vec<_>>();
    crate_context
        .into_iter()
        .map(|info| info.files)
        .flatten()
        .for_each(|file| {
            println!("cargo:rerun-if-changed={}", file.file_path);
        });
    proto_crates
}

pub fn gen_files(name: &str, root: &str) {
    let root_absolute_path = std::fs::canonicalize(".").unwrap().as_path().display().to_string();
    for protobuf_crate in gen_protos(&root_absolute_path) {
        let mut paths = vec![];
        let mut file_names = vec![];

        let proto_relative_path = suffix_relative_to_path(&protobuf_crate.proto_output_dir(), &root_absolute_path);

        for (path, file_name) in WalkDir::new(proto_relative_path)
            .into_iter()
            .filter_map(|e| e.ok())
            .map(|e| {
                let path = e.path().to_str().unwrap().to_string();
                let file_name = e.path().file_stem().unwrap().to_str().unwrap().to_string();
                (path, file_name)
            })
        {
            if path.ends_with(".proto") {
                // https://stackoverflow.com/questions/49077147/how-can-i-force-build-rs-to-run-again-without-cleaning-my-whole-project
                println!("cargo:rerun-if-changed={}", path);
                paths.push(path);
                file_names.push(file_name);
            }
        }
        println!("cargo:rerun-if-changed=build.rs");

        #[cfg(feature = "dart")]
        gen_pb_for_dart(name, root, &paths, &file_names);

        protoc_rust::Codegen::new()
            .out_dir("./src/protobuf/model")
            .inputs(&paths)
            .include(root)
            .run()
            .expect("Running protoc failed.");
    }
}

#[cfg(feature = "dart")]
fn gen_pb_for_dart(name: &str, root: &str, paths: &Vec<String>, file_names: &Vec<String>) {
    let output = format!(
        "{}/{}/{}",
        env!("CARGO_MAKE_WORKING_DIRECTORY"),
        env!("FLUTTER_FLOWY_SDK_PATH"),
        name
    );
    if !std::path::Path::new(&output).exists() {
        std::fs::create_dir_all(&output).unwrap();
    }
    check_pb_compiler();

    check_pb_dart_plugin();

    paths.iter().for_each(|path| {
        if cmd_lib::run_cmd! {
            protoc --dart_out=${output} --proto_path=${root} ${path}
        }
        .is_err()
        {
            panic!("Generate pb file failed with: {}", path)
        };
    });

    let protobuf_dart = format!("{}/protobuf.dart", output);
    match std::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .append(false)
        .truncate(true)
        .open(&protobuf_dart)
    {
        Ok(ref mut file) => {
            let mut export = String::new();
            export.push_str("// Auto-generated, do not edit \n");
            for file_name in file_names {
                let c = format!("export './{}.pb.dart';\n", file_name);
                export.push_str(c.as_ref());
            }

            file.write_all(export.as_bytes()).unwrap();
            File::flush(file).unwrap();
        }
        Err(err) => {
            panic!("Failed to open file: {}", err);
        }
    }
}

fn check_pb_compiler() {
    assert!(run_command("command -v protoc"), "protoc was not installed correctly");
}

fn check_pb_dart_plugin() {
    assert!(
        run_command("command -v protoc-gen-dart"),
        "protoc-gen-dart was not installed correctly"
    );
}

fn run_command(cmd: &str) -> bool {
    let output = if cfg!(target_os = "windows") {
        Command::new("cmd")
            .arg("/C")
            .arg(cmd)
            .status()
            .expect("failed to execute process")
    } else {
        Command::new("sh")
            .arg("-c")
            .arg(cmd)
            .status()
            .expect("failed to execute process")
    };
    output.success()
}
