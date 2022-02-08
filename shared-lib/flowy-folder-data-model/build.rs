use lib_infra::pb;

fn main() {
    pb::gen("flowy-folder-data-model", "./src/protobuf/proto");
}
