use flowy_codegen::protobuf_file::{gen_proto_files, gen_rust_proto_files};

fn main() {
  let proto_crates = gen_proto_files("flowy-error");

  #[cfg(feature = "dart")]
  flowy_codegen::protobuf_file::dart_gen2("flowy-error", &proto_crates);

  #[cfg(feature = "tauri_ts")]
  flowy_codegen::protobuf_file::ts_gen2(
    "flowy-error",
    &proto_crates,
    flowy_codegen::Project::Tauri,
  );

  #[cfg(feature = "web_ts")]
  flowy_codegen::protobuf_file::ts_gen2(
    "flowy-error",
    &proto_crates,
    flowy_codegen::Project::Web {
      relative_path: "../../".to_string(),
    },
  );

  gen_rust_proto_files(proto_crates);
}
