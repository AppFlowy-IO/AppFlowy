use lib_infra::pb;

fn main() {
    pb::gen("flowy-folder", "./src/protobuf/proto");
}
