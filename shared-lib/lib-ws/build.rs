use lib_infra::pb;

fn main() {
    pb::gen_files("lib-ws", "./src/protobuf/proto");
}
