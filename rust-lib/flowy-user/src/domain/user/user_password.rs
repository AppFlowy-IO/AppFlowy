use fancy_regex::Regex;
use lazy_static::lazy_static;
use unicode_segmentation::UnicodeSegmentation;
#[derive(Debug)]
pub struct UserPassword(pub String);

impl UserPassword {
    pub fn parse(s: String) -> Result<UserPassword, String> {
        let is_empty_or_whitespace = s.trim().is_empty();
        if is_empty_or_whitespace {
            return Err(format!("Password can not be empty or whitespace."));
        }
        let is_too_long = s.graphemes(true).count() > 100;
        let forbidden_characters = ['/', '(', ')', '"', '<', '>', '\\', '{', '}'];
        let contains_forbidden_characters = s.chars().any(|g| forbidden_characters.contains(&g));
        let is_invalid_password = !validate_password(&s);

        if is_too_long || contains_forbidden_characters || is_invalid_password {
            Err(format!("{} is not a valid password.", s))
        } else {
            Ok(Self(s))
        }
    }
}

lazy_static! {
    // Test it in https://regex101.com/
    // https://stackoverflow.com/questions/2370015/regular-expression-for-password-validation/2370045
    // Hell1!
    // [invalid, less than 6]
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

pub fn validate_password(password: &str) -> bool { PASSWORD.is_match(password).is_ok() }
