use std::env;
fn main() {
    env::set_var("TAURI_FLOWY_SDK_PATH", "appflowy_tauri/src");
    tauri_build::build()
}
