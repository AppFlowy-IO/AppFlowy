pub(crate) fn invalid_email_test_case() -> Vec<String> {
  // https://gist.github.com/cjaoude/fd9910626629b53c4d25
  [
    "annie@",
    "annie@gmail@",
    "#@%^%#$@#$@#.com",
    "@example.com",
    "Joe Smith <email@example.com>",
    "email.example.com",
    "email@example@example.com",
    "email@-example.com",
    "email@example..com",
    "あいうえお@example.com",
  ]
  .iter()
  .map(|s| s.to_string())
  .collect::<Vec<_>>()
}

pub(crate) fn invalid_password_test_case() -> Vec<String> {
  ["123456", "1234".repeat(100).as_str()]
    .iter()
    .map(|s| s.to_string())
    .collect::<Vec<_>>()
}

pub(crate) fn valid_name() -> String {
  "AppFlowy".to_string()
}
