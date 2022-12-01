fn main() {
    let crate_name = env!("CARGO_PKG_NAME");
    flowy_codegen::protobuf_file::gen(crate_name);

    #[cfg(feature = "dart")]
    flowy_codegen::dart_event::gen(crate_name);
}
