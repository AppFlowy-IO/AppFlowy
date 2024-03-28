fn main() {
  #[cfg(feature = "dart")]
  {
    flowy_codegen::protobuf_file::dart_gen(env!("CARGO_PKG_NAME"));
    flowy_codegen::dart_event::gen(env!("CARGO_PKG_NAME"));
  }

  #[cfg(feature = "tauri_ts")]
  {
    flowy_codegen::ts_event::gen(env!("CARGO_PKG_NAME"), flowy_codegen::Project::Tauri);
    flowy_codegen::protobuf_file::ts_gen(
      env!("CARGO_PKG_NAME"),
      env!("CARGO_PKG_NAME"),
      flowy_codegen::Project::Tauri,
    );
    flowy_codegen::ts_event::gen(env!("CARGO_PKG_NAME"), flowy_codegen::Project::Tauri);
    flowy_codegen::protobuf_file::ts_gen(
      env!("CARGO_PKG_NAME"),
      env!("CARGO_PKG_NAME"),
      flowy_codegen::Project::TauriApp,
    );
  }

  #[cfg(feature = "web_ts")]
  {
    flowy_codegen::ts_event::gen(
      "folder",
      flowy_codegen::Project::Web {
        relative_path: "../../".to_string(),
      },
    );
    flowy_codegen::protobuf_file::ts_gen(
      env!("CARGO_PKG_NAME"),
      "folder",
      flowy_codegen::Project::Web {
        relative_path: "../../".to_string(),
      },
    );
  }
}
