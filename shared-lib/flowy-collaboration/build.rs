use lib_infra::pb;

fn main() {
    pb::gen_files(env!("CARGO_PKG_NAME"), "./src/protobuf/proto");
}
