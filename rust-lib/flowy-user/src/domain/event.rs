use derive_more::Display;
use flowy_derive::ProtoBuf_Enum;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum)]
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

// impl std::convert::TryFrom<&crate::protobuf::UserEvent> for UserEvent {
//     type Error = String;
//     fn try_from(pb: &crate::protobuf::UserEvent) -> Result<Self, Self::Error>
// {         let a = UserEvent::SignIn;
//         match pb {
//             crate::protobuf::UserEvent::AuthCheck => { UserEvent::SignIn }
//             UserEvent::SignIn => { UserEvent::SignIn }
//             UserEvent::SignUp => {UserEvent::SignIn }
//             UserEvent::SignOut => {UserEvent::SignIn}
//         }
//     }
// }
