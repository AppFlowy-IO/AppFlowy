use lib_infra::pb;

fn main() {
    pb::gen("flowy-user-data-model", "./src/protobuf/proto");
}
