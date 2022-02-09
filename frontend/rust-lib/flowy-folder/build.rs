use lib_infra::pb;

fn main() {
    pb::gen_files("flowy-folder", "./src/protobuf/proto");
}
