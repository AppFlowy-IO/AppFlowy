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
        | "DocumentClientWSData"
        | "DocumentServerWSData"
        | "NewDocumentUser"
        | "QueryAppRequest"
        | "AppId"
        | "CreateAppRequest"
        | "ColorStyle"
        | "CreateAppParams"
        | "App"
        | "RepeatedApp"
        | "UpdateAppRequest"
        | "UpdateAppParams"
        | "UpdateWorkspaceRequest"
        | "UpdateWorkspaceParams"
        | "CurrentWorkspaceSetting"
        | "CreateWorkspaceRequest"
        | "CreateWorkspaceParams"
        | "Workspace"
        | "RepeatedWorkspace"
        | "QueryWorkspaceRequest"
        | "WorkspaceId"
        | "RepeatedTrashId"
        | "TrashId"
        | "Trash"
        | "RepeatedTrash"
        | "UpdateViewRequest"
        | "UpdateViewParams"
        | "QueryViewRequest"
        | "ViewId"
        | "RepeatedViewId"
        | "CreateViewRequest"
        | "CreateViewParams"
        | "View"
        | "RepeatedView"
        | "ExportRequest"
        | "ExportData"
        | "WSError"
        | "WebSocketRawMessage"
        => TypeCategory::Protobuf,
        "WorkspaceEvent"
        | "WorkspaceNotification"
        | "DocObservable"
        | "FFIStatusCode"
        | "NetworkEvent"
        | "NetworkType"
        | "UserEvent"
        | "UserNotification"
        | "RevisionState"
        | "RevType"
        | "DocumentClientWSDataType"
        | "DocumentServerWSDataType"
        | "TrashType"
        | "ViewType"
        | "ExportType"
        | "ErrorCode"
        | "WSModule"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
