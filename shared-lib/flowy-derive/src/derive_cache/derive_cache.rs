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
        | "SubscribeObject"
        | "FlowyError"
        | "NetworkState"
        | "UserToken"
        | "UserProfile"
        | "UpdateUserRequest"
        | "UpdateUserParams"
        | "SignInRequest"
        | "SignInParams"
        | "SignInResponse"
        | "SignUpRequest"
        | "SignUpParams"
        | "SignUpResponse"
        | "UserPreferences"
        | "AppearanceSettings"
        | "LocaleSettings"
        | "App"
        | "RepeatedApp"
        | "CreateAppRequest"
        | "ColorStyle"
        | "CreateAppParams"
        | "QueryAppRequest"
        | "AppId"
        | "UpdateAppRequest"
        | "UpdateAppParams"
        | "ExportRequest"
        | "ExportData"
        | "View"
        | "RepeatedView"
        | "CreateViewRequest"
        | "CreateViewParams"
        | "QueryViewRequest"
        | "ViewId"
        | "RepeatedViewId"
        | "UpdateViewRequest"
        | "UpdateViewParams"
        | "Trash"
        | "RepeatedTrash"
        | "RepeatedTrashId"
        | "TrashId"
        | "Workspace"
        | "RepeatedWorkspace"
        | "CreateWorkspaceRequest"
        | "CreateWorkspaceParams"
        | "QueryWorkspaceRequest"
        | "WorkspaceId"
        | "CurrentWorkspaceSetting"
        | "UpdateWorkspaceRequest"
        | "UpdateWorkspaceParams"
        | "ClientRevisionWSData"
        | "ServerRevisionWSData"
        | "NewDocumentUser"
        | "CreateDocParams"
        | "DocumentInfo"
        | "ResetDocumentParams"
        | "DocumentDelta"
        | "NewDocUser"
        | "DocumentId"
        | "Revision"
        | "RepeatedRevision"
        | "RevId"
        | "RevisionRange"
        | "FolderInfo"
        | "WSError"
        | "WebSocketRawMessage"
        => TypeCategory::Protobuf,
        "FFIStatusCode"
        | "FolderEvent"
        | "FolderNotification"
        | "UserEvent"
        | "UserNotification"
        | "NetworkEvent"
        | "NetworkType"
        | "ExportType"
        | "ViewType"
        | "TrashType"
        | "ClientRevisionWSDataType"
        | "ServerRevisionWSDataType"
        | "RevisionState"
        | "RevType"
        | "ErrorCode"
        | "WSChannel"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
