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
        "ObservableSubject"
        | "KeyValue"
        | "QueryAppRequest"
        | "CreateAppRequest"
        | "ColorStyle"
        | "App"
        | "RepeatedApp"
        | "UpdateAppRequest"
        | "DeleteAppRequest"
        | "UpdateWorkspaceRequest"
        | "DeleteWorkspaceRequest"
        | "CreateWorkspaceRequest"
        | "Workspace"
        | "Workspaces"
        | "QueryWorkspaceRequest"
        | "CurrentWorkspace"
        | "UpdateViewRequest"
        | "DeleteViewRequest"
        | "QueryViewRequest"
        | "CreateViewRequest"
        | "View"
        | "RepeatedView"
        | "WorkspaceError"
        | "CreateDocRequest"
        | "DocInfo"
        | "DocData"
        | "QueryDocRequest"
        | "QueryDocDataRequest"
        | "UpdateDocRequest"
        | "DocError"
        | "FFIRequest"
        | "FFIResponse"
        | "UserDetail"
        | "UpdateUserRequest"
        | "SignUpRequest"
        | "SignUpParams"
        | "SignUpResponse"
        | "SignInRequest"
        | "SignInParams"
        | "SignInResponse"
        | "UserError"
        => TypeCategory::Protobuf,
        "ViewType"
        | "WorkspaceEvent"
        | "WsErrCode"
        | "WorkspaceObservable"
        | "EditorEvent"
        | "DocErrorCode"
        | "FFIStatusCode"
        | "UserStatus"
        | "UserEvent"
        | "UserErrCode"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
