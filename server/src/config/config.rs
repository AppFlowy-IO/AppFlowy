use std::convert::TryFrom;

pub struct Config {
    pub http_port: u16,
}

impl Config {
    pub fn new() -> Self { Config { http_port: 3030 } }

    pub fn server_addr(&self) -> String { format!("0.0.0.0:{}", self.http_port) }
}

pub enum Environment {
    Local,
    Production,
}

impl Environment {
    #[allow(dead_code)]
    pub fn as_str(&self) -> &'static str {
        match self {
            Environment::Local => "local",
            Environment::Production => "production",
        }
    }
}

impl TryFrom<String> for Environment {
    type Error = String;

    fn try_from(s: String) -> Result<Self, Self::Error> {
        match s.to_lowercase().as_str() {
            "local" => Ok(Self::Local),
            "production" => Ok(Self::Production),
            other => Err(format!(
                "{} is not a supported environment. Use either `local` or `production`.",
                other
            )),
        }
    }
}
