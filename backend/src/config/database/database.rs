use serde::Deserialize;

#[derive(Deserialize)]
pub struct DatabaseConfig {
    username: String,
    password: String,
    port: u16,
    host: String,
    database_name: String,
}

impl DatabaseConfig {
    pub fn connect_url(&self) -> String {
        format!(
            "postgres://{}:{}@{}:{}/{}",
            self.username, self.password, self.host, self.port, self.database_name
        )
    }

    pub fn set_env_db_url(&self) {
        let url = self.connect_url();
        std::env::set_var("DATABASE_URL", url);
    }
}

impl std::default::Default for DatabaseConfig {
    fn default() -> DatabaseConfig {
        let toml_str: &str = include_str!("config.toml");
        let config: DatabaseConfig = toml::from_str(toml_str).unwrap();
        config.set_env_db_url();
        config
    }
}
