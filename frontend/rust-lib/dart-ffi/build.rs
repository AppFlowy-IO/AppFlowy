use lib_infra::pb;

fn main() {
    pb::gen("dart-ffi", "./src/protobuf/proto");
}
