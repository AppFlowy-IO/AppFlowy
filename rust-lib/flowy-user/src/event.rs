use derive_more::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash)]
pub enum UserEvent {
    #[display(fmt = "AuthCheck")]
    AuthCheck = 0,
    #[display(fmt = "SignIn")]
    SignIn    = 1,
    #[display(fmt = "SignUp")]
    SignUp    = 2,
    #[display(fmt = "SignOut")]
    SignOut   = 3,
}
