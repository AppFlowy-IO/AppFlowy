use lib_infra::pb_gen;

fn main() {
    pb_gen::gen("lib-ws", "./src/protobuf/proto");
}
