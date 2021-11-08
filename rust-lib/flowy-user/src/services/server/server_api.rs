use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile},
    errors::UserError,
    services::server::UserServerAPI,
};
use flowy_backend_api::user_request::*;
use flowy_infra::future::ResultFuture;
use flowy_net::config::*;

pub struct UserServer {
    config: ServerConfig,
}
impl UserServer {
    pub fn new(config: ServerConfig) -> Self { Self { config } }
}

impl UserServerAPI for UserServer {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        let url = self.config.sign_up_url();
        ResultFuture::new(async move {
            let resp = user_sign_up_request(params, &url).await?;
            Ok(resp)
        })
    }

    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        let url = self.config.sign_in_url();
        ResultFuture::new(async move {
            let resp = user_sign_in_request(params, &url).await?;
            Ok(resp)
        })
    }

    fn sign_out(&self, token: &str) -> ResultFuture<(), UserError> {
        let token = token.to_owned();
        let url = self.config.sign_out_url();
        ResultFuture::new(async move {
            let _ = user_sign_out_request(&token, &url).await;
            Ok(())
        })
    }

    fn update_user(&self, token: &str, params: UpdateUserParams) -> ResultFuture<(), UserError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        ResultFuture::new(async move {
            let _ = update_user_profile_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn get_user(&self, token: &str) -> ResultFuture<UserProfile, UserError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        ResultFuture::new(async move {
            let profile = get_user_profile_request(&token, &url).await?;
            Ok(profile)
        })
    }

    fn ws_addr(&self) -> String { self.config.ws_addr() }
}

// use crate::notify::*;
// use flowy_net::response::FlowyResponse;
// use flowy_user_infra::errors::ErrorCode;

// struct Middleware {}
//
//
//
// impl ResponseMiddleware for Middleware {
//     fn receive_response(&self, token: &Option<String>, response:
// &FlowyResponse) {         if let Some(error) = &response.error {
//             if error.is_unauthorized() {
//                 log::error!("user unauthorized");
//                 match token {
//                     None => {},
//                     Some(token) => {
//                         let error =
// UserError::new(ErrorCode::UserUnauthorized, "");
// dart_notify(token, UserNotification::UserUnauthorized)
// .error(error)                             .send()
//                     },
//                 }
//             }
//         }
//     }
// }
