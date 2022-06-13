use crate::entities::trash::{Trash, TrashType};
use crate::entities::{RepeatedTrash, TrashId};
use serde::{Deserialize, Serialize};

#[derive(Default, Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct TrashRevision {
    pub id: String,

    pub name: String,

    pub modified_time: i64,

    pub create_time: i64,

    pub ty: TrashType,
}

impl std::convert::From<Vec<TrashRevision>> for RepeatedTrash {
    fn from(trash_revs: Vec<TrashRevision>) -> Self {
        let items: Vec<Trash> = trash_revs.into_iter().map(|trash_rev| trash_rev.into()).collect();
        RepeatedTrash { items }
    }
}

impl std::convert::From<TrashRevision> for Trash {
    fn from(trash_rev: TrashRevision) -> Self {
        Trash {
            id: trash_rev.id,
            name: trash_rev.name,
            modified_time: trash_rev.modified_time,
            create_time: trash_rev.create_time,
            ty: trash_rev.ty,
        }
    }
}

impl std::convert::From<Trash> for TrashRevision {
    fn from(trash: Trash) -> Self {
        TrashRevision {
            id: trash.id,
            name: trash.name,
            modified_time: trash.modified_time,
            create_time: trash.create_time,
            ty: trash.ty,
        }
    }
}

impl std::convert::From<&TrashRevision> for TrashId {
    fn from(trash: &TrashRevision) -> Self {
        TrashId {
            id: trash.id.clone(),
            ty: trash.ty.clone(),
        }
    }
}
