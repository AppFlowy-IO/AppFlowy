use lib_infra::pb;

fn main() {
    pb::gen_files("flowy-collaboration", "./src/protobuf/proto");
}
