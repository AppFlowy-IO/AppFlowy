use lazy_static::lazy_static;

pub const HOST: &'static str = "localhost:8000";
pub const SCHEMA: &'static str = "http://";
pub const HEADER_TOKEN: &'static str = "token";

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

    pub static ref WS_ADDR: String = format!("ws://{}/ws", HOST);
}
