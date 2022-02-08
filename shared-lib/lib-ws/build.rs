use lib_infra::pb;

fn main() {
    pb::gen("lib-ws", "./src/protobuf/proto");
}
