use lib_infra::pb;

fn main() {
    pb::gen("dart-notify", "./src/protobuf/proto");
}
