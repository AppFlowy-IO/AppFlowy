use crate::revision::{TrashRevision, WorkspaceRevision};
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
                let f = |map: &mut A,
                         workspaces: &mut Option<Vec<WorkspaceRevision>>,
                         trash: &mut Option<Vec<TrashRevision>>| match map.next_key::<String>()
                {
                    Ok(Some(key)) => {
                        if key == "workspaces" && workspaces.is_none() {
                            *workspaces = Some(map.next_value::<Vec<WorkspaceRevision>>().ok()?);
                        }
                        if key == "trash" && trash.is_none() {
                            *trash = Some(map.next_value::<Vec<TrashRevision>>().ok()?);
                        }
                        Some(())
                    }
                    Ok(None) => None,
                    Err(_e) => None,
                };

                let mut workspaces: Option<Vec<WorkspaceRevision>> = None;
                let mut trash: Option<Vec<TrashRevision>> = None;
                while f(&mut map, &mut workspaces, &mut trash).is_some() {
                    if workspaces.is_some() && trash.is_some() {
                        break;
                    }
                }

                *self.0 = Some(FolderRevision {
                    workspaces: workspaces.unwrap_or_default().into_iter().map(Arc::new).collect(),
                    trash: trash.unwrap_or_default().into_iter().map(Arc::new).collect(),
                });
                Ok(())
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
