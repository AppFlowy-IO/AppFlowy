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
        | "CreateAppRequest"
        | "ColorStyle"
        | "App"
        | "UpdateAppRequest"
        | "UpdateWorkspaceRequest"
        | "CreateWorkspaceRequest"
        | "Workspace"
        | "UserWorkspace"
        | "UserWorkspaceDetail"
        | "CreateViewRequest"
        | "View"
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
        | "FFIStatusCode"
        | "UserStatus"
        | "UserEvent"
        | "UserErrorCode"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
