use crate::entities::{UserProfile, UserStatus};
use lib_infra::entities::network_state::NetworkState;
use tokio::sync::{broadcast, mpsc};

pub struct UserNotifier {
    user_status_notifier: broadcast::Sender<UserStatus>,
    network_status_notifier: broadcast::Sender<NetworkState>,
}

impl std::default::Default for UserNotifier {
    fn default() -> Self {
        let (user_status_notifier, _) = broadcast::channel(10);
        let (network_status_notifier, _) = broadcast::channel(10);
        UserNotifier {
            user_status_notifier,
            network_status_notifier,
        }
    }
}

impl UserNotifier {
    pub(crate) fn new() -> Self { UserNotifier::default() }

    pub(crate) fn notify_login(&self, token: &str) {
        let _ = self.user_status_notifier.send(UserStatus::Login {
            token: token.to_owned(),
        });
    }

    pub(crate) fn notify_sign_up(&self, ret: mpsc::Sender<()>, user_profile: &UserProfile) {
        let _ = self.user_status_notifier.send(UserStatus::SignUp {
            profile: user_profile.clone(),
            ret,
        });
    }

    pub(crate) fn notify_logout(&self, token: &str) {
        let _ = self.user_status_notifier.send(UserStatus::Logout {
            token: token.to_owned(),
        });
    }

    pub fn update_network_state(&self, state: NetworkState) { let _ = self.network_status_notifier.send(state); }

    pub fn user_status_subscribe(&self) -> broadcast::Receiver<UserStatus> { self.user_status_notifier.subscribe() }

    pub fn network_status_subscribe(&self) -> broadcast::Receiver<NetworkState> {
        self.network_status_notifier.subscribe()
    }
}
