#[derive(Debug)]
pub struct UserPassword(pub String);

impl UserPassword {
    pub fn parse(s: String) -> Result<UserPassword, String> { Ok(Self(s)) }
}
