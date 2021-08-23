use crate::{
    config::env::{domain, jwt_secret},
    entities::user::User,
};
use chrono::{Duration, Local};
use derive_more::{From, Into};
use flowy_net::errors::{ErrorCode, ServerError};
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
    email: String,
}

impl Claim {
    pub fn with_email(email: &str) -> Self {
        let domain = domain();
        Self {
            iss: domain,
            sub: "auth".to_string(),
            email: email.to_string(),
            iat: Local::now().timestamp(),
            exp: (Local::now() + Duration::hours(24)).timestamp(),
        }
    }
}

// impl From<Claim> for User {
//     fn from(claim: Claim) -> Self { Self { email: claim.email } }
// }

#[derive(From, Into)]
pub struct Token(String);
impl Token {
    pub fn create_token(data: &User) -> Result<Self, ServerError> {
        let claims = Claim::with_email(&data.email);
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
}
