use lib_infra::pb;

fn main() {
    pb::gen("flowy-net", "./src/protobuf/proto");
}
