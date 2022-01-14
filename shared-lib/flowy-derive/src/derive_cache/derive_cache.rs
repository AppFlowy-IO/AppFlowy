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
        | "ClientRevisionWSData"
        | "ServerRevisionWSData"
        | "NewDocumentUser"
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
        | "RepeatedTrashId"
        | "TrashId"
        | "Trash"
        | "RepeatedTrash"
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
        | "RevisionState"
        | "RevType"
        | "ClientRevisionWSDataType"
        | "ServerRevisionWSDataType"
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
