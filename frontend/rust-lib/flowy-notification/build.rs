fn main() {
  #[cfg(feature = "dart")]
  flowy_codegen::protobuf_file::dart_gen("flowy-error");

  #[cfg(feature = "tauri_ts")]
  flowy_codegen::protobuf_file::ts_gen("flowy-error", flowy_codegen::Project::Tauri);

  #[cfg(feature = "web_ts")]
  flowy_codegen::protobuf_file::ts_gen(
    "flowy-error",
    flowy_codegen::Project::Web {
      relative_path: "../../".to_string(),
    },
  );
}
