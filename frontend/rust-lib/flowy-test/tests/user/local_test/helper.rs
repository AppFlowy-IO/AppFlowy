pub(crate) fn invalid_email_test_case() -> Vec<String> {
  // https://gist.github.com/cjaoude/fd9910626629b53c4d25
  vec![
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
    /* The following email is valid according to the validate_email function return
     * ".email@example.com",
     * "email.@example.com",
     * "email..email@example.com",
     * "email@example",
     * "email@example.web",
     * "email@111.222.333.44444",
     * "Abc..123@example.com", */
  ]
  .iter()
  .map(|s| s.to_string())
  .collect::<Vec<_>>()
}

pub(crate) fn invalid_password_test_case() -> Vec<String> {
  vec!["123456", "1234".repeat(100).as_str()]
    .iter()
    .map(|s| s.to_string())
    .collect::<Vec<_>>()
}

pub(crate) fn valid_name() -> String {
  "AppFlowy".to_string()
}
