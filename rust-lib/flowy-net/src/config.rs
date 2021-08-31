use lazy_static::lazy_static;

pub const HOST: &'static str = "http://localhost:8000";

lazy_static! {
    pub static ref SIGN_UP_URL: String = format!("{}/api/register", HOST);
    pub static ref SIGN_IN_URL: String = format!("{}/api/auth", HOST);
    pub static ref USER_DETAIL_URL: String = format!("{}/api/auth", HOST);
    pub static ref SIGN_OUT_URL: String = format!("{}/api/auth", HOST);
}
