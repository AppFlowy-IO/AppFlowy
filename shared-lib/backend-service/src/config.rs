pub const HOST: &str = "localhost:8000";
pub const HTTP_SCHEMA: &str = "http";
pub const WS_SCHEMA: &str = "ws";
pub const HEADER_TOKEN: &str = "token";

#[derive(Debug, Clone)]
pub struct ServerConfig {
    http_schema: String,
    host: String,
    ws_schema: String,
}

impl std::default::Default for ServerConfig {
    fn default() -> Self {
        ServerConfig {
            http_schema: HTTP_SCHEMA.to_string(),
            host: HOST.to_string(),
            ws_schema: WS_SCHEMA.to_string(),
        }
    }
}

impl ServerConfig {
    pub fn new(host: &str, http_schema: &str, ws_schema: &str) -> Self {
        Self {
            http_schema: http_schema.to_owned(),
            host: host.to_owned(),
            ws_schema: ws_schema.to_owned(),
        }
    }

    fn scheme(&self) -> String { format!("{}://", self.http_schema) }

    pub fn sign_up_url(&self) -> String { format!("{}{}/api/register", self.scheme(), self.host) }

    pub fn sign_in_url(&self) -> String { format!("{}{}/api/auth", self.scheme(), self.host) }

    pub fn sign_out_url(&self) -> String { format!("{}{}/api/auth", self.scheme(), self.host) }

    pub fn user_profile_url(&self) -> String { format!("{}{}/api/user", self.scheme(), self.host) }

    pub fn workspace_url(&self) -> String { format!("{}{}/api/workspace", self.scheme(), self.host) }

    pub fn app_url(&self) -> String { format!("{}{}/api/app", self.scheme(), self.host) }

    pub fn view_url(&self) -> String { format!("{}{}/api/view", self.scheme(), self.host) }

    pub fn doc_url(&self) -> String { format!("{}{}/api/doc", self.scheme(), self.host) }

    pub fn trash_url(&self) -> String { format!("{}{}/api/trash", self.scheme(), self.host) }

    pub fn ws_addr(&self) -> String { format!("{}://{}/ws", self.ws_schema, self.host) }
}
