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
        "WorkspaceError"
        | "DocError"
        | "FFIRequest"
        | "FFIResponse"
        | "SubscribeObject"
        | "NetworkState"
        | "UserError"
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
        | "CreateDocParams"
        | "Doc"
        | "UpdateDocParams"
        | "DocDelta"
        | "NewDocUser"
        | "DocIdentifier"
        | "WsDocumentData"
        | "WsError"
        | "WsMessage"
        | "Revision"
        | "RevId"
        | "RevisionRange"
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
        => TypeCategory::Protobuf,
        "WorkspaceEvent"
        | "WorkspaceNotification"
        | "ErrorCode"
        | "DocObservable"
        | "FFIStatusCode"
        | "NetworkType"
        | "UserEvent"
        | "UserNotification"
        | "TrashType"
        | "ViewType"
        | "ExportType"
        | "WsDataType"
        | "WsModule"
        | "RevType"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
