use lazy_static::lazy_static;

pub const HOST: &'static str = "http://localhost:8000";

pub const HEADER_TOKEN: &'static str = "token";

lazy_static! {
    pub static ref SIGN_UP_URL: String = format!("{}/api/register", HOST);
    pub static ref SIGN_IN_URL: String = format!("{}/api/auth", HOST);
    pub static ref SIGN_OUT_URL: String = format!("{}/api/auth", HOST);
    pub static ref USER_PROFILE_URL: String = format!("{}/api/user", HOST);

    //
    pub static ref WORKSPACE_URL: String = format!("{}/api/workspace", HOST);
    pub static ref APP_URL: String = format!("{}/api/app", HOST);
    pub static ref VIEW_URL: String = format!("{}/api/view", HOST);

    //
    pub static ref DOC_URL: String = format!("{}/api/doc", HOST);
}
