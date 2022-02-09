use lib_infra::pb;

fn main() {
    pb::gen_files("flowy-user", "./src/protobuf/proto");
}
