#![allow(unused_imports)]
use std::fs::File;
use std::io::Write;
use walkdir::WalkDir;

pub fn gen(name: &str, root: &str) {
    let mut paths = vec![];
    let mut file_names = vec![];
    for (path, file_name) in WalkDir::new(root).into_iter().filter_map(|e| e.ok()).map(|e| {
        let path = e.path().to_str().unwrap().to_string();
        let file_name = e.path().file_stem().unwrap().to_str().unwrap().to_string();
        (path, file_name)
    }) {
        if path.ends_with(".proto") {
            // https://stackoverflow.com/questions/49077147/how-can-i-force-build-rs-to-run-again-without-cleaning-my-whole-project
            println!("cargo:rerun-if-changed={}", path);
            paths.push(path);
            file_names.push(file_name);
        }
    }

    #[cfg(feature = "dart")]
    gen_pb_for_dart(name, root, &paths, &file_names);

    protoc_rust::Codegen::new()
        .out_dir("./src/protobuf/model")
        .inputs(&paths)
        .include(root)
        .run()
        .expect("Running protoc failed.");
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
    paths.iter().for_each(|path| {
        if cmd_lib::run_cmd! {
            protoc --dart_out=${output} --proto_path=${root} ${path}
        }
        .is_err()
        {
            panic!("Run flutter protoc fail")
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
