use flowy_error::ErrorCode;
use validator::ValidateEmail;

#[derive(Debug)]
pub struct UserEmail(pub String);

impl UserEmail {
  pub fn parse(s: String) -> Result<UserEmail, ErrorCode> {
    if s.trim().is_empty() {
      return Err(ErrorCode::EmailIsEmpty);
    }

    if ValidateEmail::validate_email(&s) {
      Ok(Self(s))
    } else {
      Err(ErrorCode::EmailFormatInvalid)
    }
  }
}

impl AsRef<str> for UserEmail {
  fn as_ref(&self) -> &str {
    &self.0
  }
}

#[cfg(test)]
mod tests {
  use fake::{faker::internet::en::SafeEmail, Fake};
  use rand::prelude::StdRng;
  use rand_core::SeedableRng;

  use super::*;

  #[test]
  fn empty_string_is_rejected() {
    let email = "".to_string();
    assert!(UserEmail::parse(email).is_err());
  }

  #[test]
  fn email_missing_at_symbol_is_rejected() {
    let email = "helloworld.com".to_string();
    assert!(UserEmail::parse(email).is_err());
  }

  #[test]
  fn email_missing_subject_is_rejected() {
    let email = "@domain.com".to_string();
    assert!(UserEmail::parse(email).is_err());
  }

  #[derive(Debug, Clone)]
  struct ValidEmailFixture(pub String);

  impl quickcheck::Arbitrary for ValidEmailFixture {
    fn arbitrary(g: &mut quickcheck::Gen) -> Self {
      let mut rand_slice: [u8; 32] = [0; 32];
      #[allow(clippy::needless_range_loop)]
      for i in 0..32 {
        rand_slice[i] = u8::arbitrary(g);
      }
      let mut seed = StdRng::from_seed(rand_slice);
      let email = SafeEmail().fake_with_rng(&mut seed);
      Self(email)
    }
  }

  #[quickcheck_macros::quickcheck]
  fn valid_emails_are_parsed_successfully(valid_email: ValidEmailFixture) -> bool {
    UserEmail::parse(valid_email.0).is_ok()
  }
}
