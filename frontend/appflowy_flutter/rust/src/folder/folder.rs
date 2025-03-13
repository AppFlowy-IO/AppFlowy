use anyhow;
use client_api::Client;
use flutter_rust_bridge::frb;

use super::entities::FolderListResponse;

#[derive(Debug, Clone)]
pub(crate) struct FolderManager {
    pub base_url: String,
    client: reqwest::Client,
    url_provider: FolderHttpUrlProvider,
}

impl FolderManager {
    #[frb(sync)]
    pub fn new(base_url: String) -> Self {
        Self {
            base_url: base_url.clone(),
            client: reqwest::Client::new(),
            url_provider: FolderHttpUrlProvider::new(base_url),
        }
    }

    #[tokio::main(flavor = "current_thread")]
    // {{APPFLOWY_BASE_URL}}/api/workspace/{{CURRENT_WORKSPACE_ID}}/folder?depth=10&root_view_id={{CURRENT_WORKSPACE_ID}}
    pub async fn get_folder_list(
        &self,
        workspace_id: String,
        depth: Option<i32>,
        root_view_id: Option<String>,
        bearer_token: String,
    ) -> anyhow::Result<FolderListResponse> {
        let url = self
            .url_provider
            .get_folder_list_url(workspace_id, depth, root_view_id);
        println!("[x] url: {}", url);
        let resp = self
            .client
            .get(url)
            .header("Authorization", format!("Bearer {}", bearer_token))
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .send()
            .await?;
        let text = resp.text().await?;
        println!("[x] text: {}", text);
        let resp = serde_json::from_str::<FolderListResponse>(&text)?;
        println!("[x] resp: {:?}", resp);
        Ok(resp)
    }
}

#[derive(Debug, Clone)]
#[frb(ignore)]
struct FolderHttpUrlProvider {
    base_url: String,
}

impl FolderHttpUrlProvider {
    pub fn new(base_url: String) -> Self {
        Self { base_url }
    }

    pub fn get_folder_list_url(
        &self,
        workspace_id: String,
        depth: Option<i32>,
        root_view_id: Option<String>,
    ) -> String {
        format!(
            "{}/api/workspace/{}/folder?depth={}&root_view_id={}",
            self.base_url,
            &workspace_id,
            depth.unwrap_or(10),
            root_view_id.as_deref().unwrap_or(&workspace_id)
        )
    }
}
