use anyhow;
use flutter_rust_bridge::frb;
use std::collections::HashMap;

#[frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[derive(Debug, Clone)]
pub(crate) struct FolderManager {
    // TODO: use client instead of http request
    // client: Client,
    pub base_url: String,
    pub workspace_id: String,
}

impl FolderManager {
    #[frb(sync)]
    pub fn new(base_url: String, workspace_id: String) -> Self {
        Self {
            base_url,
            workspace_id,
        }
    }

    #[tokio::main(flavor = "current_thread")]
    pub async fn get_folder_list(&self) -> anyhow::Result<HashMap<String, String>> {
        // Create a client and add bearer token to the request header
        let client = reqwest::Client::new();
        let resp = client
            .get(format!(
                "{}/api/v1/workspaces/{}/folders",
                self.base_url, self.workspace_id
            ))
            .header("Authorization", format!("Bearer {}", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDlmNjM4My0wNTdjLTQwZDctOGRiMi0wMjRjNGRkN2YyODMiLCJhdWQiOiIiLCJleHAiOjE3NDIzMDEwNjAsImlhdCI6MTc0MTY5NjI2MCwiZW1haWwiOiJsdWNhcy54dUBhcHBmbG93eS5pbyIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiR29vZ2xlIiwicHJvdmlkZXJzIjpbIkdvb2dsZSIsImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSXgyWTFrRlJnZXk2bU5lNng0bWtMVGFRRjF1bHh2S08tUjhmVHEtS0h0bFluUGtBPXM5Ni1jIiwiY3VzdG9tX2NsYWltcyI6eyJoZCI6ImFwcGZsb3d5LmlvIn0sImVtYWlsIjoibHVjYXMueHVAYXBwZmxvd3kuaW8iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZnVsbF9uYW1lIjoiTHVjYXMgWHUiLCJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJuYW1lIjoiTHVjYXMgWHUiLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJeDJZMWtGUmdleTZtTmU2eDRta0xUYVFGMXVseHZLTy1SOGZUcS1LSHRsWW5Qa0E9czk2LWMiLCJwcm92aWRlcl9pZCI6IjExMTgwODEyOTgzNTM5MzE2MDc0NSIsInN1YiI6IjExMTgwODEyOTgzNTM5MzE2MDc0NSJ9LCJyb2xlIjoiIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3NDE2OTYyNjB9XSwic2Vzc2lvbl9pZCI6ImE3ZTAxNWExLTdkNWQtNDQ5Mi05ZDNkLWQ1NTRkNzI2MmNmYiIsImlzX2Fub255bW91cyI6ZmFsc2V9.wawUHS7apw9t6_SaE4pKY-Uc-SEorR9df4fe2AVGbc8")) // TODO: Replace with actual token from configuration
            .send()
            .await?
            .json::<HashMap<String, String>>()
            .await?;
        Ok(resp)
    }
}
