fn main() {
    #[cfg(feature = "dart")]
    {
        println!("Generating Dart protobuf code for package: {}", env!("CARGO_PKG_NAME"));
        flowy_codegen::protobuf_file::dart_gen(env!("CARGO_PKG_NAME"));
    }
    
    #[cfg(not(feature = "dart"))]
    {
        println!("Dart feature not enabled; skipping code generation.");
    }
}
