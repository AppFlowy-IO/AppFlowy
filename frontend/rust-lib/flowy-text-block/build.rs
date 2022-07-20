use lib_infra::code_gen;

fn main() {
    let crate_name = env!("CARGO_PKG_NAME");
    code_gen::protobuf_file::gen(crate_name);

    #[cfg(feature = "dart")]
    code_gen::dart_event::gen(crate_name);
}
