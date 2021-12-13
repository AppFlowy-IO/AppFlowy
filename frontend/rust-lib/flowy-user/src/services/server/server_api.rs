use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile},
    errors::UserError,
    services::server::UserServerAPI,
};
use backend_service::{configuration::*, user_request::*};
use lib_infra::future::FutureResult;

pub struct UserHttpServer {
    config: ClientServerConfiguration,
}
impl UserHttpServer {
    pub fn new(config: ClientServerConfiguration) -> Self { Self { config } }
}

impl UserServerAPI for UserHttpServer {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, UserError> {
        let url = self.config.sign_up_url();
        FutureResult::new(async move {
            let resp = user_sign_up_request(params, &url).await?;
            Ok(resp)
        })
    }

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, UserError> {
        let url = self.config.sign_in_url();
        FutureResult::new(async move {
            let resp = user_sign_in_request(params, &url).await?;
            Ok(resp)
        })
    }

    fn sign_out(&self, token: &str) -> FutureResult<(), UserError> {
        let token = token.to_owned();
        let url = self.config.sign_out_url();
        FutureResult::new(async move {
            let _ = user_sign_out_request(&token, &url).await;
            Ok(())
        })
    }

    fn update_user(&self, token: &str, params: UpdateUserParams) -> FutureResult<(), UserError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
            let _ = update_user_profile_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn get_user(&self, token: &str) -> FutureResult<UserProfile, UserError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
            let profile = get_user_profile_request(&token, &url).await?;
            Ok(profile)
        })
    }

    fn ws_addr(&self) -> String { self.config.ws_addr() }
}

// use crate::notify::*;
// use backend_service::response::FlowyResponse;
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
