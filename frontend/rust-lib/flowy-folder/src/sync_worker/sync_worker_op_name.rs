// Page operations
pub const CREATE_PAGE_OPERATION_NAME: &str = "create_page";
pub const UPDATE_PAGE_OPERATION_NAME: &str = "update_page";
pub const MOVE_PAGE_OPERATION_NAME: &str = "move_page";
pub const MOVE_PAGE_TO_TRASH_OPERATION_NAME: &str = "move_page_to_trash";
pub const RESTORE_PAGE_FROM_TRASH_OPERATION_NAME: &str = "restore_page_from_trash";
pub const DELETE_PAGE_OPERATION_NAME: &str = "delete_page";

// Space operations
pub const CREATE_SPACE_OPERATION_NAME: &str = "create_space";
pub const UPDATE_SPACE_OPERATION_NAME: &str = "update_space";
// Note: The move space to trash, restore space from trash and delete space operations are using the same workflow as the move page to trash, restore page from trash and delete page operations

// Http methods
pub const HTTP_METHOD_POST: &str = "POST";
pub const HTTP_METHOD_PUT: &str = "PUT";
pub const HTTP_METHOD_DELETE: &str = "DELETE";

// Http status
pub const HTTP_STATUS_PENDING: &str = "pending";
pub const HTTP_STATUS_COMPLETED: &str = "completed";
