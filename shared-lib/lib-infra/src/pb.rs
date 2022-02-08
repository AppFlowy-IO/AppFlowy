use walkdir::WalkDir;

pub fn gen(name: &str, root: &str) {
    let mut paths = vec![];
    for path in WalkDir::new(root)
        .into_iter()
        .filter_map(|e| e.ok())
        .map(|e| e.path().to_str().unwrap().to_string())
    {
        if path.ends_with(".proto") {
            // https://stackoverflow.com/questions/49077147/how-can-i-force-build-rs-to-run-again-without-cleaning-my-whole-project
            println!("cargo:rerun-if-changed={}", path);
            paths.push(path);
        }
    }
    let flutter_pb_path = format!(
        "{}/{}/{}",
        env!("CARGO_MAKE_WORKING_DIRECTORY"),
        env!("FLUTTER_FLOWY_SDK_PATH"),
        name
    );
    paths.iter().for_each(|path| {
        if cmd_lib::run_cmd! {
            protoc --dart_out=${flutter_pb_path} --proto_path=${root} ${path}
        }
        .is_err()
        {
            panic!("Run flutter protoc fail")
        };
    });

    protoc_rust::Codegen::new()
        .out_dir("./src/protobuf/model")
        .inputs(&paths)
        .include(root)
        .run()
        .expect("Running protoc failed.");
}
