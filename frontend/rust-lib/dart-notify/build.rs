use lib_infra::pb_gen;

fn main() {
    pb_gen::gen("dart-notify", "./src/protobuf/proto");
}
