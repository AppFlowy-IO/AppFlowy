use flowy_derive::ProtoBuf;
use std::convert::TryInto;

use crate::{
    entities::parser::{UserEmail, UserIcon, UserId, UserName, UserPassword},
    errors::ErrorCode,
};

#[derive(Default, ProtoBuf)]
pub struct UserTokenPB {
    #[pb(index = 1)]
    pub token: String,
}

#[derive(ProtoBuf, Default, Debug, PartialEq, Eq, Clone)]
pub struct UserProfilePB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub email: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub token: String,

    #[pb(index = 5)]
    pub icon: String,
}

#[derive(ProtoBuf, Default)]
pub struct UpdateUserProfilePayloadPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub email: Option<String>,

    #[pb(index = 4, one_of)]
    pub password: Option<String>,

    #[pb(index = 5, one_of)]
    pub icon: Option<String>,
}

impl UpdateUserProfilePayloadPB {
    pub fn new(id: &str) -> Self {
        Self {
            id: id.to_owned(),
            ..Default::default()
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.name = Some(name.to_owned());
        self
    }

    pub fn email(mut self, email: &str) -> Self {
        self.email = Some(email.to_owned());
        self
    }

    pub fn password(mut self, password: &str) -> Self {
        self.password = Some(password.to_owned());
        self
    }

    pub fn icon(mut self, icon: &str) -> Self {
        self.icon = Some(icon.to_owned());
        self
    }
}

#[derive(ProtoBuf, Default, Clone, Debug)]
pub struct UpdateUserProfileParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub email: Option<String>,

    #[pb(index = 4, one_of)]
    pub password: Option<String>,

    #[pb(index = 5, one_of)]
    pub icon: Option<String>,
}

impl UpdateUserProfileParams {
    pub fn new(user_id: &str) -> Self {
        Self {
            id: user_id.to_owned(),
            name: None,
            email: None,
            password: None,
            icon: None,
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.name = Some(name.to_owned());
        self
    }

    pub fn email(mut self, email: &str) -> Self {
        self.email = Some(email.to_owned());
        self
    }

    pub fn password(mut self, password: &str) -> Self {
        self.password = Some(password.to_owned());
        self
    }

    pub fn icon(mut self, icon: &str) -> Self {
        self.icon = Some(icon.to_owned());
        self
    }
}

impl TryInto<UpdateUserProfileParams> for UpdateUserProfilePayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateUserProfileParams, Self::Error> {
        let id = UserId::parse(self.id)?.0;

        let name = match self.name {
            None => None,
            Some(name) => Some(UserName::parse(name)?.0),
        };

        let email = match self.email {
            None => None,
            Some(email) => Some(UserEmail::parse(email)?.0),
        };

        let password = match self.password {
            None => None,
            Some(password) => Some(UserPassword::parse(password)?.0),
        };

        let icon = match self.icon {
            None => None,
            Some(icon) => Some(UserIcon::parse(icon)?.0),
        };

        Ok(UpdateUserProfileParams {
            id,
            name,
            email,
            password,
            icon,
        })
    }
}
