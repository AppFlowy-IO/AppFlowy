use crate::entities::UserProfilePB;
use tokio::sync::{broadcast, mpsc};

#[derive(Clone)]
pub enum UserStatus {
    Login {
        token: String,
        user_id: String,
    },
    Logout {
        token: String,
        user_id: String,
    },
    Expired {
        token: String,
        user_id: String,
    },
    SignUp {
        profile: UserProfilePB,
        ret: mpsc::Sender<()>,
    },
}

pub struct UserNotifier {
    user_status_notifier: broadcast::Sender<UserStatus>,
}

impl std::default::Default for UserNotifier {
    fn default() -> Self {
        let (user_status_notifier, _) = broadcast::channel(10);
        UserNotifier { user_status_notifier }
    }
}

impl UserNotifier {
    pub(crate) fn new() -> Self {
        UserNotifier::default()
    }

    pub(crate) fn notify_login(&self, token: &str, user_id: &str) {
        let _ = self.user_status_notifier.send(UserStatus::Login {
            token: token.to_owned(),
            user_id: user_id.to_owned(),
        });
    }

    pub(crate) fn notify_sign_up(&self, ret: mpsc::Sender<()>, user_profile: &UserProfilePB) {
        let _ = self.user_status_notifier.send(UserStatus::SignUp {
            profile: user_profile.clone(),
            ret,
        });
    }

    pub(crate) fn notify_logout(&self, token: &str, user_id: &str) {
        let _ = self.user_status_notifier.send(UserStatus::Logout {
            token: token.to_owned(),
            user_id: user_id.to_owned(),
        });
    }

    pub fn subscribe_user_status(&self) -> broadcast::Receiver<UserStatus> {
        self.user_status_notifier.subscribe()
    }
}
