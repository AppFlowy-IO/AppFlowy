use lib_infra::pb;

fn main() {
    pb::gen("flowy-user", "./src/protobuf/proto");
}
