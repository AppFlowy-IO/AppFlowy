use lib_infra::pb;

fn main() {
    pb::gen("flowy-error", "./src/protobuf/proto");
}
