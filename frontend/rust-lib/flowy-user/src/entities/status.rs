use crate::entities::UserProfile;
use tokio::sync::mpsc;

#[derive(Clone)]
pub enum UserStatus {
    Login {
        token: String,
    },
    Logout {
        token: String,
    },
    Expired {
        token: String,
    },
    SignUp {
        profile: UserProfile,
        ret: mpsc::Sender<()>,
    },
}
