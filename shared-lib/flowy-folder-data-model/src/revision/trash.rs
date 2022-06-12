use crate::entities::trash::{Trash, TrashType};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct TrashRevision {
    pub id: String,

    pub name: String,

    pub modified_time: i64,

    pub create_time: i64,

    pub ty: TrashType,
}

impl std::convert::From<TrashRevision> for Trash {
    fn from(trash_serde: TrashRevision) -> Self {
        Trash {
            id: trash_serde.id,
            name: trash_serde.name,
            modified_time: trash_serde.modified_time,
            create_time: trash_serde.create_time,
            ty: trash_serde.ty,
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
