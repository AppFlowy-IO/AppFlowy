use lib_infra::pb;

fn main() {
    pb::gen_files("error-code", "./src/protobuf/proto");
}
