use crate::{entities::app::App, impl_def_and_def_mut};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct Trash {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub modified_time: i64,

    #[pb(index = 4)]
    pub create_time: i64,

    #[pb(index = 5)]
    pub ty: TrashType,
}

#[derive(PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedTrash {
    #[pb(index = 1)]
    pub items: Vec<Trash>,
}

impl_def_and_def_mut!(RepeatedTrash, Trash);

impl std::convert::From<App> for Trash {
    fn from(app: App) -> Self {
        Trash {
            id: app.id,
            name: app.name,
            modified_time: app.modified_time,
            create_time: app.create_time,
            ty: TrashType::TrashApp,
        }
    }
}

#[derive(Eq, PartialEq, Debug, ProtoBuf_Enum, Clone, Serialize, Deserialize)]
pub enum TrashType {
    Unknown = 0,
    TrashView = 1,
    TrashApp = 2,
}

impl std::convert::TryFrom<i32> for TrashType {
    type Error = String;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(TrashType::Unknown),
            1 => Ok(TrashType::TrashView),
            2 => Ok(TrashType::TrashApp),
            _ => Err(format!("Invalid trash type: {}", value)),
        }
    }
}

impl std::default::Default for TrashType {
    fn default() -> Self {
        TrashType::Unknown
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedTrashId {
    #[pb(index = 1)]
    pub items: Vec<TrashId>,

    #[pb(index = 2)]
    pub delete_all: bool,
}

impl std::fmt::Display for RepeatedTrashId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!(
            "{:?}",
            &self.items.iter().map(|item| format!("{}", item)).collect::<Vec<_>>()
        ))
    }
}

impl RepeatedTrashId {
    pub fn all() -> RepeatedTrashId {
        RepeatedTrashId {
            items: vec![],
            delete_all: true,
        }
    }
}

impl std::convert::From<Vec<TrashId>> for RepeatedTrashId {
    fn from(items: Vec<TrashId>) -> Self {
        RepeatedTrashId {
            items,
            delete_all: false,
        }
    }
}

impl std::convert::From<Vec<Trash>> for RepeatedTrashId {
    fn from(trash: Vec<Trash>) -> Self {
        let items = trash
            .into_iter()
            .map(|t| TrashId { id: t.id, ty: t.ty })
            .collect::<Vec<_>>();

        RepeatedTrashId {
            items,
            delete_all: false,
        }
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashId {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub ty: TrashType,
}

impl std::convert::From<&Trash> for TrashId {
    fn from(trash: &Trash) -> Self {
        TrashId {
            id: trash.id.clone(),
            ty: trash.ty.clone(),
        }
    }
}

impl std::fmt::Display for TrashId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!("{:?}:{}", self.ty, self.id))
    }
}
