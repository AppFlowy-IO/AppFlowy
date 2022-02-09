use lib_infra::pb;

fn main() {
    pb::gen_files("dart-notify", "./src/protobuf/proto");
}
