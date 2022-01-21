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
        | "WSError"
        | "WebSocketRawMessage"
        => TypeCategory::Protobuf,
        "WorkspaceEvent"
        | "WorkspaceNotification"
        | "FFIStatusCode"
        | "NetworkEvent"
        | "NetworkType"
        | "UserEvent"
        | "UserNotification"
        | "ClientRevisionWSDataType"
        | "ServerRevisionWSDataType"
        | "RevisionState"
        | "RevType"
        | "ExportType"
        | "TrashType"
        | "ViewType"
        | "ErrorCode"
        | "WSModule"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
