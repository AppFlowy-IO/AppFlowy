use lib_infra::pb;

fn main() {
    pb::gen_files("flowy-user-data-model", "./src/protobuf/proto");
}
