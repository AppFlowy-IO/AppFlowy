use lazy_static::lazy_static;

pub const HOST: &'static str = "localhost:8000";
pub const SCHEMA: &'static str = "http://";
pub const HEADER_TOKEN: &'static str = "token";

#[derive(Debug, Clone)]
pub struct ServerConfig {
    http_schema: String,
    host: String,
    ws_schema: String,
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

    pub fn ws_addr(&self) -> String { format!("{}://{}/ws", self.ws_schema, self.host) }
}

lazy_static! {
    pub static ref SIGN_UP_URL: String = format!("{}/{}/api/register", SCHEMA, HOST);
    pub static ref SIGN_IN_URL: String = format!("{}/{}/api/auth", SCHEMA, HOST);
    pub static ref SIGN_OUT_URL: String = format!("{}/{}/api/auth", SCHEMA, HOST);
    pub static ref USER_PROFILE_URL: String = format!("{}/{}/api/user", SCHEMA, HOST);

    //
    pub static ref WORKSPACE_URL: String = format!("{}/{}/api/workspace", SCHEMA, HOST);
    pub static ref APP_URL: String = format!("{}/{}/api/app", SCHEMA, HOST);
    pub static ref VIEW_URL: String = format!("{}/{}/api/view", SCHEMA, HOST);
    pub static ref DOC_URL: String = format!("{}/{}/api/doc", SCHEMA, HOST);

    //
    pub static ref WS_ADDR: String = format!("ws://{}/ws", HOST);
}
