use lib_infra::code_gen;
use lib_infra::code_gen::dart_event;

fn main() {
    code_gen::protobuf_file::gen(env!("CARGO_PKG_NAME"), "./src/protobuf/proto");
    #[cfg(feature = "flutter")]
    copy_dart_event_files();
}

#[cfg(feature = "flutter")]
fn copy_dart_event_files() {
    let workspace_dir = std::env::var("CARGO_MAKE_WORKING_DIRECTORY").unwrap();
    let flutter_sdk_path = std::env::var("FLUTTER_FLOWY_SDK_PATH").unwrap();
    let output_file = format!("{}/{}/lib/dispatch/code_gen.dart", workspace_dir, flutter_sdk_path);
    dart_event::write_dart_event_file(&output_file);
}
