use lib_infra::pb;

fn main() {
    pb::gen("error-code", "./src/protobuf/proto");
}
