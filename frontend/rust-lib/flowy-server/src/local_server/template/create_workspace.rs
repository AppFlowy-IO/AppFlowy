use collab::entity::EncodedCollab;
use tracing::warn;
use uuid::Uuid;
use workspace_template::document::vault_template::VaultTemplate;
use workspace_template::{TemplateObjectId, WorkspaceTemplateBuilder};

pub async fn create_workspace_for_user(
  uid: i64,
  workspace_id: &Uuid,
) -> anyhow::Result<Vec<CreateWorkspaceCollab>> {
  let templates = WorkspaceTemplateBuilder::new(uid, workspace_id)
    .with_templates(vec![VaultTemplate])
    .build()
    .await?;

  let mut collab_params = Vec::with_capacity(templates.len());
  for template in templates {
    let template_id = template.template_id;
    let (_, object_id) = match &template_id {
      TemplateObjectId::Document(oid) => (oid.to_string(), oid.to_string()),
      TemplateObjectId::Folder(oid) => (oid.to_string(), oid.to_string()),
      _ => {
        warn!("Unsupported template type: {:?}", template_id,);
        continue;
      },
    };
    let object_id = Uuid::parse_str(&object_id)?;
    collab_params.push(CreateWorkspaceCollab {
      object_id,
      encoded_collab: template.encoded_collab,
    });
  }

  Ok(collab_params)
}

pub struct CreateWorkspaceCollab {
  pub object_id: Uuid,
  pub encoded_collab: EncodedCollab,
}
