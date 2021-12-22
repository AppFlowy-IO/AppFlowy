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
        | "Doc"
        | "UpdateDocParams"
        | "DocDelta"
        | "NewDocUser"
        | "DocIdentifier"
        | "Revision"
        | "RepeatedRevision"
        | "RevId"
        | "RevisionRange"
        | "DocumentWSData"
        | "NewDocumentUser"
        | "QueryAppRequest"
        | "AppIdentifier"
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
        | "WorkspaceIdentifier"
        | "TrashIdentifiers"
        | "TrashIdentifier"
        | "Trash"
        | "RepeatedTrash"
        | "UpdateViewRequest"
        | "UpdateViewParams"
        | "QueryViewRequest"
        | "ViewIdentifier"
        | "ViewIdentifiers"
        | "CreateViewRequest"
        | "CreateViewParams"
        | "View"
        | "RepeatedView"
        | "ExportRequest"
        | "ExportData"
        | "WSError"
        | "WSMessage"
        => TypeCategory::Protobuf,
        "WorkspaceEvent"
        | "WorkspaceNotification"
        | "DocObservable"
        | "FFIStatusCode"
        | "NetworkEvent"
        | "NetworkType"
        | "UserEvent"
        | "UserNotification"
        | "RevType"
        | "RevState"
        | "DocumentWSDataType"
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
