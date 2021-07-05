mod proto;
mod util;

use clap::{App, Arg};

fn main() {
    std::env::set_var("RUST_LOG", "Debug");
    env_logger::init();

    let matches = app().get_matches();

    if let Some(ref matches) = matches.subcommand_matches("pb-gen") {
        let rust_source = matches.value_of("rust_source").unwrap();
        let derive_meta = matches.value_of("derive_meta").unwrap();
        let rust_mod_dir = matches.value_of("rust_mod_dir").unwrap();
        let flutter_mod_dir = matches.value_of("flutter_mod_dir").unwrap();
        let proto_file_output = matches.value_of("proto_file_output").unwrap();

        proto::ProtoGenBuilder::new()
            .set_rust_source_dir(rust_source)
            .set_derive_meta_dir(derive_meta)
            .set_rust_mod_dir(rust_mod_dir)
            .set_flutter_mod_dir(flutter_mod_dir)
            .set_proto_file_output_dir(proto_file_output)
            .build()
            .gen();
    }
}

pub fn app<'a, 'b>() -> App<'a, 'b> {
    let app = App::new("flowy-tool")
        .version("0.1")
        .author("nathan")
        .about("flowy tool")
        .subcommand(
            App::new("pb-gen")
                .about("Generate proto file from rust code")
                .arg(
                    Arg::with_name("rust_source")
                        .long("rust_source")
                        .value_name("DIRECTORY")
                        .help("Directory of the cargo workspace"),
                )
                .arg(
                    Arg::with_name("derive_meta")
                        .long("derive_meta")
                        .value_name("PATH")
                        .help("Caching information used by flowy-derive"),
                )
                .arg(
                    Arg::with_name("rust_mod_dir")
                        .long("rust_mod_dir")
                        .value_name("DIRECTORY"),
                )
                .arg(
                    Arg::with_name("flutter_mod_dir")
                        .long("flutter_mod_dir")
                        .value_name("DIRECTORY"),
                )
                .arg(
                    Arg::with_name("proto_file_output")
                        .long("proto_file_output")
                        .value_name("DIRECTORY")
                        .help("The path is used to save the generated proto file"),
                ),
        );

    app
}
