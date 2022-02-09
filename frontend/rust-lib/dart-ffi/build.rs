use lib_infra::pb;

fn main() {
    pb::gen_files("dart-ffi", "./src/protobuf/proto");
}
