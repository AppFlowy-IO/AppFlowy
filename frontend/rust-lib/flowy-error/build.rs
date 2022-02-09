use lib_infra::pb;

fn main() {
    pb::gen_files("flowy-error", "./src/protobuf/proto");
}
