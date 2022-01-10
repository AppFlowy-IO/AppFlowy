use crate::FlowyError;
use backend_service::configuration::ClientServerConfiguration;
use flowy_net::cloud::user::{UserHttpCloudService, UserLocalCloudService};
use flowy_user::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile},
    module::UserCloudService,
};
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct UserDepsResolver();
impl UserDepsResolver {
    pub fn resolve(server_config: &ClientServerConfiguration) -> Arc<dyn UserCloudService> {
        make_user_cloud_service(server_config)
    }
}

fn make_user_cloud_service(config: &ClientServerConfiguration) -> Arc<dyn UserCloudService> {
    if cfg!(feature = "http_server") {
        Arc::new(UserHttpCloudServiceAdaptor(UserHttpCloudService::new(config)))
    } else {
        Arc::new(UserLocalCloudServiceAdaptor(UserLocalCloudService::new(config)))
    }
}

struct UserHttpCloudServiceAdaptor(UserHttpCloudService);
impl UserCloudService for UserHttpCloudServiceAdaptor {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> { self.0.sign_up(params) }

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> { self.0.sign_in(params) }

    fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError> { self.0.sign_out(token) }

    fn update_user(&self, token: &str, params: UpdateUserParams) -> FutureResult<(), FlowyError> {
        self.0.update_user(token, params)
    }

    fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError> { self.0.get_user(token) }

    fn ws_addr(&self) -> String { self.0.ws_addr() }
}

struct UserLocalCloudServiceAdaptor(UserLocalCloudService);
impl UserCloudService for UserLocalCloudServiceAdaptor {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> { self.0.sign_up(params) }

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> { self.0.sign_in(params) }

    fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError> { self.0.sign_out(token) }

    fn update_user(&self, token: &str, params: UpdateUserParams) -> FutureResult<(), FlowyError> {
        self.0.update_user(token, params)
    }

    fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError> { self.0.get_user(token) }

    fn ws_addr(&self) -> String { self.0.ws_addr() }
}
