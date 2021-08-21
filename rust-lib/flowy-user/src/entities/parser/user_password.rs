use crate::errors::UserErrCode;
use fancy_regex::Regex;
use lazy_static::lazy_static;
use unicode_segmentation::UnicodeSegmentation;

#[derive(Debug)]
pub struct UserPassword(pub String);

impl UserPassword {
    pub fn parse(s: String) -> Result<UserPassword, UserErrCode> {
        if s.trim().is_empty() {
            return Err(UserErrCode::PasswordIsEmpty);
        }

        if s.graphemes(true).count() > 100 {
            return Err(UserErrCode::PasswordTooLong);
        }

        let forbidden_characters = ['/', '(', ')', '"', '<', '>', '\\', '{', '}'];
        let contains_forbidden_characters = s.chars().any(|g| forbidden_characters.contains(&g));
        if contains_forbidden_characters {
            return Err(UserErrCode::PasswordContainsForbidCharacters);
        }

        if !validate_password(&s) {
            return Err(UserErrCode::PasswordFormatInvalid);
        }

        Ok(Self(s))
    }
}

lazy_static! {
    // Test it in https://regex101.com/
    // https://stackoverflow.com/questions/2370015/regular-expression-for-password-validation/2370045
    // Hell1!
    // [invalid, greater or equal to 6]
    // Hel1!
    //
    // Hello1!
    // [invalid, must include number]
    // Hello!
    //
    // Hello12!
    // [invalid must include upper case]
    // hello12!
    static ref PASSWORD: Regex = Regex::new("((?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\\W]).{6,20})").unwrap();
}

pub fn validate_password(password: &str) -> bool {
    match PASSWORD.is_match(password) {
        Ok(is_match) => is_match,
        Err(e) => {
            log::error!("validate_password fail: {:?}", e);
            false
        },
    }
}
