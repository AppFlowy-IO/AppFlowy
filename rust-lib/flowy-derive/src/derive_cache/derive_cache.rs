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
        | "QueryAppParams"
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
        | "UpdateViewRequest"
        | "UpdateViewParams"
        | "SaveViewDataRequest"
        | "ApplyChangesetRequest"
        | "DeleteViewRequest"
        | "DeleteViewParams"
        | "QueryViewRequest"
        | "QueryViewParams"
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
        | "QueryDocParams"
        | "WsDocumentData"
        | "DocError"
        | "FFIRequest"
        | "FFIResponse"
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
        "ViewType"
        | "WorkspaceEvent"
        | "ErrorCode"
        | "WorkspaceObservable"
        | "WsSource"
        | "DocObservable"
        | "FFIStatusCode"
        | "UserEvent"
        | "UserObservable"
        => TypeCategory::Enum,

        "Option" => TypeCategory::Opt,
        _ => TypeCategory::Primitive,
    }
}
