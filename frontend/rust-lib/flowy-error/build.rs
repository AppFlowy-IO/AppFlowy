fn main() {
  #[cfg(feature = "dart")]
  flowy_codegen::protobuf_file::dart_gen(env!("CARGO_PKG_NAME"));
}
