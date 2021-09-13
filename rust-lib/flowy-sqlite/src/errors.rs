use error_chain::{error_chain, error_chain_processing, impl_error_chain_kind, impl_error_chain_processed, impl_extract_backtrace};

error_chain! {
    errors {
        UnknownMigrationExists(v: String) {
             display("unknown migration version: '{}'", v),
        }
    }
    foreign_links {
        R2D2(::r2d2::Error);
        Migrations(::diesel_migrations::RunMigrationsError);
        Diesel(::diesel::result::Error);
        Connection(::diesel::ConnectionError);
        Io(::std::io::Error);
    }
}
