use std::env;
fn main() {
    env::set_var("TAURI_PROTOBUF_PATH", "appflowy_tauri/src/protobuf");
    env::set_var("CARGO_MAKE_WORKING_DIRECTORY", "../../../");

    tauri_build::build()
}
