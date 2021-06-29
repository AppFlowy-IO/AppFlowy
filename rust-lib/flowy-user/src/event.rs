use derive_more::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash)]
pub enum UserEvent {
    #[display(fmt = "AuthCheck")]
    AuthCheck = 0,
    SignIn    = 1,
    SignUp    = 2,
    SignOut   = 3,
}
