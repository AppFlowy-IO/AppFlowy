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
        "KeyValue"
        | "QueryAppRequest"
        | "AppIdentifier"
        | "CreateAppRequest"
        | "ColorStyle"
        | "CreateAppParams"
        | "App"
        | "RepeatedApp"
        | "UpdateAppRequest"
        | "UpdateAppParams"
        | "DeleteAppRequest"
        | "DeleteAppParams"
        | "UpdateWorkspaceRequest"
        | "UpdateWorkspaceParams"
        | "DeleteWorkspaceRequest"
        | "DeleteWorkspaceParams"
        | "CreateWorkspaceRequest"
        | "CreateWorkspaceParams"
        | "Workspace"
        | "RepeatedWorkspace"
        | "QueryWorkspaceRequest"
        | "QueryWorkspaceParams"
        | "CurrentWorkspace"
        | "TrashIdentifiers"
        | "TrashIdentifier"
        | "Trash"
        | "RepeatedTrash"
        | "UpdateViewRequest"
        | "UpdateViewParams"
        | "DeleteViewRequest"
        | "DeleteViewParams"
        | "QueryViewRequest"
        | "ViewIdentifier"
        | "OpenViewRequest"
        | "CreateViewRequest"
        | "CreateViewParams"
        | "View"
        | "RepeatedView"
        | "WorkspaceError"
        | "WsError"
        | "WsMessage"
        | "CreateDocParams"
        | "Doc"
        | "UpdateDocParams"
        | "DocDelta"
        | "NewDocUser"
        | "DocIdentifier"
        | "RevId"
        | "Revision"
        | "RevisionRange"
        | "WsDocumentData"
        | "DocError"
        | "FFIRequest"
        | "FFIResponse"
        | "SubscribeObject"
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
        | "UserError"
        => TypeCategory::Protobuf,
        "TrashType"
        | "ViewType"
        | "WorkspaceEvent"
        | "ErrorCode"
        | "WorkspaceNotification"
        | "WsModule"
        | "RevType"
        | "WsDataType"
        | "DocObservable"
        | "FFIStatusCode"
        | "UserEvent"
        | "UserNotification"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
