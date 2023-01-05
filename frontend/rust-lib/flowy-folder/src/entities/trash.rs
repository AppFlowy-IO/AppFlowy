use crate::impl_def_and_def_mut;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use folder_rev_model::{TrashRevision, TrashTypeRevision};
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashPB {
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

impl std::convert::From<TrashRevision> for TrashPB {
    fn from(trash_rev: TrashRevision) -> Self {
        TrashPB {
            id: trash_rev.id,
            name: trash_rev.name,
            modified_time: trash_rev.modified_time,
            create_time: trash_rev.create_time,
            ty: trash_rev.ty.into(),
        }
    }
}

impl std::convert::From<TrashPB> for TrashRevision {
    fn from(trash: TrashPB) -> Self {
        TrashRevision {
            id: trash.id,
            name: trash.name,
            modified_time: trash.modified_time,
            create_time: trash.create_time,
            ty: trash.ty.into(),
        }
    }
}
#[derive(PartialEq, Eq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedTrashPB {
    #[pb(index = 1)]
    pub items: Vec<TrashPB>,
}

impl_def_and_def_mut!(RepeatedTrashPB, TrashPB);
impl std::convert::From<Vec<TrashRevision>> for RepeatedTrashPB {
    fn from(trash_revs: Vec<TrashRevision>) -> Self {
        let items: Vec<TrashPB> = trash_revs.into_iter().map(|trash_rev| trash_rev.into()).collect();
        RepeatedTrashPB { items }
    }
}

#[derive(Eq, PartialEq, Debug, ProtoBuf_Enum, Clone, Serialize, Deserialize)]
pub enum TrashType {
    TrashUnknown = 0,
    TrashView = 1,
    TrashApp = 2,
}

impl std::convert::TryFrom<i32> for TrashType {
    type Error = String;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(TrashType::TrashUnknown),
            1 => Ok(TrashType::TrashView),
            2 => Ok(TrashType::TrashApp),
            _ => Err(format!("Invalid trash type: {}", value)),
        }
    }
}

impl std::convert::From<TrashTypeRevision> for TrashType {
    fn from(rev: TrashTypeRevision) -> Self {
        match rev {
            TrashTypeRevision::Unknown => TrashType::TrashUnknown,
            TrashTypeRevision::TrashView => TrashType::TrashView,
            TrashTypeRevision::TrashApp => TrashType::TrashApp,
        }
    }
}

impl std::convert::From<TrashType> for TrashTypeRevision {
    fn from(rev: TrashType) -> Self {
        match rev {
            TrashType::TrashUnknown => TrashTypeRevision::Unknown,
            TrashType::TrashView => TrashTypeRevision::TrashView,
            TrashType::TrashApp => TrashTypeRevision::TrashApp,
        }
    }
}

impl std::default::Default for TrashType {
    fn default() -> Self {
        TrashType::TrashUnknown
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedTrashIdPB {
    #[pb(index = 1)]
    pub items: Vec<TrashIdPB>,

    #[pb(index = 2)]
    pub delete_all: bool,
}

impl std::fmt::Display for RepeatedTrashIdPB {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!(
            "{:?}",
            &self.items.iter().map(|item| format!("{}", item)).collect::<Vec<_>>()
        ))
    }
}

impl RepeatedTrashIdPB {
    pub fn all() -> RepeatedTrashIdPB {
        RepeatedTrashIdPB {
            items: vec![],
            delete_all: true,
        }
    }
}

impl std::convert::From<Vec<TrashIdPB>> for RepeatedTrashIdPB {
    fn from(items: Vec<TrashIdPB>) -> Self {
        RepeatedTrashIdPB {
            items,
            delete_all: false,
        }
    }
}

impl std::convert::From<Vec<TrashRevision>> for RepeatedTrashIdPB {
    fn from(trash: Vec<TrashRevision>) -> Self {
        let items = trash
            .into_iter()
            .map(|t| TrashIdPB {
                id: t.id,
                ty: t.ty.into(),
            })
            .collect::<Vec<_>>();

        RepeatedTrashIdPB {
            items,
            delete_all: false,
        }
    }
}

#[derive(PartialEq, Eq, ProtoBuf, Default, Debug, Clone)]
pub struct TrashIdPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub ty: TrashType,
}

impl std::fmt::Display for TrashIdPB {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!("{:?}:{}", self.ty, self.id))
    }
}

impl std::convert::From<&TrashRevision> for TrashIdPB {
    fn from(trash: &TrashRevision) -> Self {
        TrashIdPB {
            id: trash.id.clone(),
            ty: trash.ty.clone().into(),
        }
    }
}
