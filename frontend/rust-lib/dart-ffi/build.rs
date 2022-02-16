use lib_infra::code_gen;

fn main() {
    code_gen::protobuf_file::gen(env!("CARGO_PKG_NAME"), "./src/protobuf/proto");
}
