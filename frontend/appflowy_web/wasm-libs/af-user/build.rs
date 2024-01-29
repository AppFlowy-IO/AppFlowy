use flowy_codegen::Project;

fn main() {
  let crate_name = env!("CARGO_PKG_NAME");

  flowy_codegen::protobuf_file::ts_gen(
    crate_name,
    Project::Web {
      relative_path: "../../../".to_string(),
    },
  );
  flowy_codegen::ts_event::gen(
    crate_name,
    Project::Web {
      relative_path: "../../../".to_string(),
    },
  );
}
