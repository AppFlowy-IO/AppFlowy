#[derive(Debug, Clone, serde::Deserialize)]
pub struct FolderListResponse {
    pub data: FolderView,
    pub code: i32,
    pub message: String,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct FolderView {
    pub view_id: String,
    pub name: String,
    pub icon: Option<FolderIcon>,
    pub is_space: bool,
    pub is_private: bool,
    pub is_published: bool,
    pub layout: i32,
    pub created_at: String,
    pub last_edited_time: String,
    pub is_locked: Option<bool>,
    pub extra: Option<FolderViewExtra>,
    pub children: Option<Vec<FolderView>>,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct FolderViewExtra {
    pub is_space: bool,
    pub space_created_at: i64,
    pub space_icon: String,
    pub space_icon_color: String,
    pub space_permission: i32,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct FolderIcon {
    pub ty: i32,
    pub value: String,
}

#[test]
fn test_raw_folder_list_json_to_folder_list_response() {
    let json = r#"
    {
  "data": {
    "view_id": "b2d11122-1fc8-474d-9ef1-ec12fea7ffe8",
    "name": "Workspace",
    "icon": null,
    "is_space": false,
    "is_private": false,
    "is_published": false,
    "layout": 0,
    "created_at": "2024-11-17T06:33:15Z",
    "last_edited_time": "2024-11-17T06:33:15Z",
    "is_locked": null,
    "extra": null,
    "children": [
      {
        "view_id": "a12b2610-05d9-43f0-a6a6-a4071c06fd64",
        "name": "Work",
        "icon": null,
        "is_space": true,
        "is_private": false,
        "is_published": false,
        "layout": 0,
        "created_at": "2025-02-28T07:52:43Z",
        "last_edited_time": "2025-03-11T03:40:57Z",
        "is_locked": null,
        "extra": {
          "is_space": true,
          "space_created_at": 1721209696723,
          "space_icon": "work_education/global-learning",
          "space_icon_color": "0xFF00C8FF",
          "space_permission": 0
        }
      },
      {
        "view_id": "9cf9aa3c-f586-4aa2-9d0a-72251e524055",
        "name": "Android JniLibs",
        "icon": {
            "ty": 0,
            "value": "1️⃣"
        },
        "is_space": false,
        "is_private": false,
        "is_published": true,
        "layout": 0,
        "created_at": "2025-03-11T03:33:49Z",
        "last_edited_time": "2025-03-13T02:41:53Z",
        "is_locked": null,
        "extra": null,
        "children": []
        }
    ]
  }
}
"#;
    let folder_list_response: FolderListResponse = serde_json::from_str(json).unwrap();
    println!("{:?}", folder_list_response);
}
