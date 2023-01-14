use crate::{TrashRevision, WorkspaceRevision};
use serde::de::{MapAccess, Visitor};
use serde::{de, Deserialize, Deserializer, Serialize};
use std::fmt;
use std::sync::Arc;

#[derive(Debug, Default, Serialize, Clone, Eq, PartialEq)]
pub struct FolderRevision {
    pub workspaces: Vec<Arc<WorkspaceRevision>>,
    pub trash: Vec<Arc<TrashRevision>>,
}

impl<'de> Deserialize<'de> for FolderRevision {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct FolderVisitor<'a>(&'a mut Option<FolderRevision>);
        impl<'de, 'a> Visitor<'de> for FolderVisitor<'a> {
            type Value = ();
            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("Expect struct FolderRevision")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut workspaces: Option<Vec<WorkspaceRevision>> = None;
                let mut trash: Option<Vec<TrashRevision>> = None;
                while let Some(key) = map.next_key::<String>()? {
                    if key == "workspaces" && workspaces.is_none() {
                        workspaces = Some(map.next_value::<Vec<WorkspaceRevision>>()?);
                    }
                    if key == "trash" && trash.is_none() {
                        trash = Some(map.next_value::<Vec<TrashRevision>>()?);
                    }
                }

                if let Some(workspaces) = workspaces {
                    *self.0 = Some(FolderRevision {
                        workspaces: workspaces.into_iter().map(Arc::new).collect(),
                        trash: trash.unwrap_or_default().into_iter().map(Arc::new).collect(),
                    });
                    Ok(())
                } else {
                    Err(de::Error::missing_field("workspaces"))
                }
            }
        }

        let mut folder_rev: Option<FolderRevision> = None;
        const FIELDS: &[&str] = &["workspaces", "trash"];
        let _ = serde::Deserializer::deserialize_struct(
            deserializer,
            "FolderRevision",
            FIELDS,
            FolderVisitor(&mut folder_rev),
        );

        match folder_rev {
            None => Err(de::Error::missing_field("workspaces or trash")),
            Some(folder_rev) => Ok(folder_rev),
        }
    }
}
