fn main() {
  let crate_name = env!("CARGO_PKG_NAME");
  flowy_codegen::protobuf_file::gen(crate_name);
  flowy_codegen::ts_event::gen(crate_name);
}
