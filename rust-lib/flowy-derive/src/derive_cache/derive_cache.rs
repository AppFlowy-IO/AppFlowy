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
        | "CreateDocRequest"
        | "DocInfo"
        | "DocData"
        | "QueryDocRequest"
        | "QueryDocDataRequest"
        | "UpdateDocRequest"
        | "EditorError"
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
        | "FFIRequest"
        | "FFIResponse"
        | "UserDetail"
        | "UpdateUserRequest"
        | "SignUpRequest"
        | "SignUpParams"
        | "SignUpResponse"
        | "SignInRequest"
        | "SignInParams"
        | "UserError"
        => TypeCategory::Protobuf,
        "EditorEvent"
        | "EditorErrorCode"
        | "ViewType"
        | "WorkspaceEvent"
        | "WsErrCode"
        | "WorkspaceObservable"
        | "FFIStatusCode"
        | "UserStatus"
        | "UserEvent"
        | "UserErrCode"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
