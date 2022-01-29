#![cfg_attr(rustfmt, rustfmt::skip)]
pub enum TypeCategory {
    Array,
    Map,
    Str,
    Protobuf,
    Bytes,
    Enum,
    Opt,
    Primitive,
}
// auto generate, do not edit
pub fn category_from_str(type_str: &str) -> TypeCategory {
    match type_str {
        "Vec" => TypeCategory::Array,
        "HashMap" => TypeCategory::Map,
        "u8" => TypeCategory::Bytes,
        "String" => TypeCategory::Str,
        "FFIRequest"
        | "FFIResponse"
        | "FlowyError"
        | "SubscribeObject"
        | "NetworkState"
        | "SignInRequest"
        | "SignInParams"
        | "SignInResponse"
        | "SignUpRequest"
        | "SignUpParams"
        | "SignUpResponse"
        | "UserToken"
        | "UserProfile"
        | "UpdateUserRequest"
        | "UpdateUserParams"
        | "UserPreferences"
        | "AppearanceSettings"
        | "ClientRevisionWSData"
        | "ServerRevisionWSData"
        | "NewDocumentUser"
        | "FolderInfo"
        | "Revision"
        | "RepeatedRevision"
        | "RevId"
        | "RevisionRange"
        | "CreateDocParams"
        | "DocumentInfo"
        | "ResetDocumentParams"
        | "DocumentDelta"
        | "NewDocUser"
        | "DocumentId"
        | "WSError"
        | "WebSocketRawMessage"
        | "Workspace"
        | "RepeatedWorkspace"
        | "CreateWorkspaceRequest"
        | "CreateWorkspaceParams"
        | "QueryWorkspaceRequest"
        | "WorkspaceId"
        | "CurrentWorkspaceSetting"
        | "UpdateWorkspaceRequest"
        | "UpdateWorkspaceParams"
        | "ExportRequest"
        | "ExportData"
        | "App"
        | "RepeatedApp"
        | "CreateAppRequest"
        | "ColorStyle"
        | "CreateAppParams"
        | "QueryAppRequest"
        | "AppId"
        | "UpdateAppRequest"
        | "UpdateAppParams"
        | "Trash"
        | "RepeatedTrash"
        | "RepeatedTrashId"
        | "TrashId"
        | "View"
        | "RepeatedView"
        | "CreateViewRequest"
        | "CreateViewParams"
        | "QueryViewRequest"
        | "ViewId"
        | "RepeatedViewId"
        | "UpdateViewRequest"
        | "UpdateViewParams"
        => TypeCategory::Protobuf,
        "FFIStatusCode"
        | "FolderEvent"
        | "FolderNotification"
        | "NetworkEvent"
        | "NetworkType"
        | "UserEvent"
        | "UserNotification"
        | "ClientRevisionWSDataType"
        | "ServerRevisionWSDataType"
        | "RevisionState"
        | "RevType"
        | "ErrorCode"
        | "WSChannel"
        | "ExportType"
        | "TrashType"
        | "ViewType"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
