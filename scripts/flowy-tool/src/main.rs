mod config;
mod proto;
mod util;

use clap::{App, Arg};

fn main() {
    std::env::set_var("RUST_LOG", "Info");
    env_logger::init();

    let matches = app().get_matches();

    if let Some(ref matches) = matches.subcommand_matches("pb-gen") {
        let rust_source = matches.value_of("rust_source").unwrap();
        let derive_meta = matches.value_of("derive_meta").unwrap();
        let flutter_package_lib = matches.value_of("flutter_package_lib").unwrap();

        proto::ProtoGenBuilder::new()
            .set_rust_source_dir(rust_source)
            .set_derive_meta_dir(derive_meta)
            .set_flutter_package_lib(flutter_package_lib)
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
                    Arg::with_name("flutter_package_lib")
                        .long("flutter_package_lib")
                        .value_name("DIRECTORY"),
                ),
        );

    app
}
