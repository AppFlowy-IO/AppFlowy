use lib_infra::pb;

fn main() {
    pb::gen_files("flowy-net", "./src/protobuf/proto");
}
