use lib_infra::pb;

fn main() {
    pb::gen("flowy-collaboration", "./src/protobuf/proto");
}
