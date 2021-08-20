use lazy_static::lazy_static;

pub const HOST: &'static str = "0.0.0.0:3030";

lazy_static! {
    pub static ref SIGN_UP_URL: String = format!("{}/user/register", HOST);
}
