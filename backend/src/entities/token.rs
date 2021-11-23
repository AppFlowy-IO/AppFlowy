use crate::config::env::{domain, jwt_secret};
use backend_service::errors::ServerError;
use chrono::{Duration, Local};
use derive_more::{From, Into};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

const DEFAULT_ALGORITHM: Algorithm = Algorithm::HS256;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claim {
    // issuer
    iss: String,
    // subject
    sub: String,
    // issue at
    iat: i64,
    // expiry
    exp: i64,
    user_id: String,
}

impl Claim {
    pub fn with_user_id(user_id: &str) -> Self {
        let domain = domain();
        Self {
            iss: domain,
            sub: "auth".to_string(),
            user_id: user_id.to_string(),
            iat: Local::now().timestamp(),
            exp: (Local::now() + Duration::days(EXPIRED_DURATION_DAYS)).timestamp(),
        }
    }

    pub fn user_id(self) -> String { self.user_id }
}

// impl From<Claim> for User {
//     fn from(claim: Claim) -> Self { Self { email: claim.email } }
// }

#[derive(From, Into, Clone)]
pub struct Token(pub String);
impl Token {
    pub fn create_token(user_id: &str) -> Result<Self, ServerError> {
        let claims = Claim::with_user_id(&user_id);
        encode(
            &Header::new(DEFAULT_ALGORITHM),
            &claims,
            &EncodingKey::from_secret(jwt_secret().as_ref()),
        )
        .map(Into::into)
        .map_err(|err| ServerError::internal().context(err))
    }

    pub fn decode_token(token: &Self) -> Result<Claim, ServerError> {
        decode::<Claim>(
            &token.0,
            &DecodingKey::from_secret(jwt_secret().as_ref()),
            &Validation::new(DEFAULT_ALGORITHM),
        )
        .map(|data| Ok(data.claims))
        .map_err(|err| ServerError::unauthorized().context(err))?
    }

    pub fn parser_from_request(request: &HttpRequest) -> Result<Self, ServerError> {
        match request.headers().get(HEADER_TOKEN) {
            Some(header) => match header.to_str() {
                Ok(val) => Ok(Token(val.to_owned())),
                Err(_) => Err(ServerError::unauthorized()),
            },
            None => Err(ServerError::unauthorized()),
        }
    }
}

use crate::service::user::EXPIRED_DURATION_DAYS;
use actix_web::{dev::Payload, FromRequest, HttpRequest};
use backend_service::config::HEADER_TOKEN;
use futures::future::{ready, Ready};

impl FromRequest for Token {
    type Error = ServerError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(request: &HttpRequest, _payload: &mut Payload) -> Self::Future {
        match Token::parser_from_request(request) {
            Ok(token) => ready(Ok(token)),
            Err(err) => ready(Err(err)),
        }
    }
}
