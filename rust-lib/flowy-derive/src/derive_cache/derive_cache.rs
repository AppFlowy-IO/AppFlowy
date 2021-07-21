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
        | "UpdateWorkspaceRequest"
        | "CreateWorkspaceRequest"
        | "Workspace"
        | "QueryWorkspaceRequest"
        | "CurrentWorkspace"
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
        "ViewTypeIdentifier"
        | "WorkspaceEvent"
        | "WorkspaceErrorCode"
        | "ObservableType"
        | "FFIStatusCode"
        | "UserStatus"
        | "UserEvent"
        | "UserErrorCode"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
