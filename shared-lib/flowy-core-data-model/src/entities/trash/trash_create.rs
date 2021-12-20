use crate::impl_def_and_def_mut;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::fmt::Formatter;

#[derive(PartialEq, Debug, ProtoBuf_Enum, Clone)]
pub enum TrashType {
    Unknown = 0,
    View    = 1,
    App     = 2,
}

impl std::convert::TryFrom<i32> for TrashType {
    type Error = String;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(TrashType::Unknown),
            1 => Ok(TrashType::View),
            2 => Ok(TrashType::App),
            _ => Err(format!("Invalid trash type: {}", value)),
        }
    }
}

impl std::default::Default for TrashType {
    fn default() -> Self { TrashType::Unknown }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashIdentifiers {
    #[pb(index = 1)]
    pub items: Vec<TrashIdentifier>,

    #[pb(index = 2)]
    pub delete_all: bool,
}

impl std::fmt::Display for TrashIdentifiers {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!(
            "{:?}",
            &self.items.iter().map(|item| format!("{}", item)).collect::<Vec<_>>()
        ))
    }
}

impl TrashIdentifiers {
    pub fn all() -> TrashIdentifiers {
        TrashIdentifiers {
            items: vec![],
            delete_all: true,
        }
    }
}

impl std::convert::From<Vec<TrashIdentifier>> for TrashIdentifiers {
    fn from(items: Vec<TrashIdentifier>) -> Self {
        TrashIdentifiers {
            items,
            delete_all: false,
        }
    }
}

impl std::convert::From<Vec<Trash>> for TrashIdentifiers {
    fn from(trash: Vec<Trash>) -> Self {
        let items = trash
            .into_iter()
            .map(|t| TrashIdentifier { id: t.id, ty: t.ty })
            .collect::<Vec<_>>();

        TrashIdentifiers {
            items,
            delete_all: false,
        }
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashIdentifier {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub ty: TrashType,
}

impl std::convert::From<&Trash> for TrashIdentifier {
    fn from(trash: &Trash) -> Self {
        TrashIdentifier {
            id: trash.id.clone(),
            ty: trash.ty.clone(),
        }
    }
}

impl std::fmt::Display for TrashIdentifier {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str(&format!("{:?}:{}", self.ty, self.id)) }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
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
