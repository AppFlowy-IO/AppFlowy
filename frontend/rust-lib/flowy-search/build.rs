fn main() {
  let crate_name = env!("CARGO_PKG_NAME");

  #[cfg(feature = "dart")]
  {
    flowy_codegen::protobuf_file::dart_gen(crate_name);
    flowy_codegen::dart_event::gen(crate_name);
  }

  #[cfg(feature = "tauri_ts")]
  {
    flowy_codegen::protobuf_file::ts_gen(crate_name);
    flowy_codegen::ts_event::gen(crate_name);
  }
}
