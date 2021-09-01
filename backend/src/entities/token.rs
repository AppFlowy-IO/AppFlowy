use crate::config::env::{domain, jwt_secret};
use chrono::{Duration, Local};
use derive_more::{From, Into};
use flowy_net::errors::ServerError;
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
            exp: (Local::now() + Duration::hours(24)).timestamp(),
        }
    }

    pub fn get_user_id(self) -> String { self.user_id }
}

// impl From<Claim> for User {
//     fn from(claim: Claim) -> Self { Self { email: claim.email } }
// }

#[derive(From, Into, Clone)]
pub struct Token(String);
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
}
