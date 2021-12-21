mod config;
mod dart_event;
mod proto;
mod util;
use clap::{App, Arg};

fn main() {
    std::env::set_var("RUST_LOG", "Info");
    env_logger::init();

    let matches = app().get_matches();

    if let Some(ref matches) = matches.subcommand_matches("pb-gen") {
        let rust_sources: Vec<String> = matches
            .values_of("rust_sources")
            .unwrap()
            .map(|value| value.to_owned())
            .collect();
        let derive_meta = matches.value_of("derive_meta").unwrap();
        let flutter_package_lib = matches.value_of("flutter_package_lib").unwrap();

        proto::ProtoGenBuilder::new()
            .set_rust_source_dirs(rust_sources)
            .set_derive_meta_dir(derive_meta)
            .set_flutter_package_lib(flutter_package_lib)
            .build()
            .gen();
    }

    if let Some(ref matches) = matches.subcommand_matches("dart-event") {
        let rust_sources: Vec<String> = matches
            .values_of("rust_sources")
            .unwrap()
            .map(|value| value.to_owned())
            .collect();
        let output_dir = matches.value_of("output").unwrap().to_string();

        let code_gen = dart_event::DartEventCodeGen {
            rust_sources,
            output_dir,
        };
        code_gen.gen();
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
                    Arg::with_name("rust_sources")
                        .long("rust_sources")
                        .multiple(true)
                        .required(true)
                        .min_values(1)
                        .value_name("DIRECTORY")
                        .help("Directories of the cargo workspace"),
                )
                .arg(
                    Arg::with_name("derive_meta")
                        .long("derive_meta")
                        .value_name("PATH")
                        .help("Caching information used by flowy-derive"),
                )
                .arg(
                    Arg::with_name("flutter_package_lib")
                        .long("flutter_package_lib")
                        .value_name("DIRECTORY"),
                ),
        )
        .subcommand(
            App::new("dart-event")
                .about("Generate the codes that sending events from rust ast")
                .arg(
                    Arg::with_name("rust_sources")
                        .long("rust_sources")
                        .multiple(true)
                        .required(true)
                        .min_values(1)
                        .value_name("DIRECTORY")
                        .help("Directories of the cargo workspace"),
                )
                .arg(
                    Arg::with_name("output")
                        .long("output")
                        .value_name("DIRECTORY"),
                ),
        );

    app
}
