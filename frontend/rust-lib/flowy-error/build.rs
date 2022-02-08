use lib_infra::pb_gen;

fn main() {
    pb_gen::gen("flowy-error", "./src/protobuf/proto");
}
