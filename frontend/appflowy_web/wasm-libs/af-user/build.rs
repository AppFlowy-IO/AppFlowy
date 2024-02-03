use flowy_codegen::Project;

fn main() {
  flowy_codegen::protobuf_file::ts_gen(
    env!("CARGO_PKG_NAME"),
    "user",
    Project::Web {
      relative_path: "../../../".to_string(),
    },
  );
  flowy_codegen::ts_event::gen(
    "user",
    Project::Web {
      relative_path: "../../../".to_string(),
    },
  );
}
