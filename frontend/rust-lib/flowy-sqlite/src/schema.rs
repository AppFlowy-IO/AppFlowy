// @generated automatically by Diesel CLI.

diesel::table! {
    chat_message_table (message_id) {
        message_id -> BigInt,
        chat_id -> Text,
        content -> Text,
        created_at -> BigInt,
        author_type -> BigInt,
        author_id -> Text,
        reply_message_id -> Nullable<BigInt>,
    }
}

diesel::table! {
    chat_table (chat_id) {
        chat_id -> Text,
        created_at -> BigInt,
        name -> Text,
    }
}

diesel::table! {
    collab_snapshot (id) {
        id -> Text,
        object_id -> Text,
        title -> Text,
        desc -> Text,
        collab_type -> Text,
        timestamp -> BigInt,
        data -> Binary,
    }
}

diesel::table! {
    user_data_migration_records (id) {
        id -> Integer,
        migration_name -> Text,
        executed_at -> Timestamp,
    }
}

diesel::table! {
    user_table (id) {
        id -> Text,
        name -> Text,
        workspace -> Text,
        icon_url -> Text,
        openai_key -> Text,
        token -> Text,
        email -> Text,
        auth_type -> Integer,
        encryption_type -> Text,
        stability_ai_key -> Text,
        updated_at -> BigInt,
        ai_model -> Text,
    }
}

diesel::table! {
    user_workspace_table (id) {
        id -> Text,
        name -> Text,
        uid -> BigInt,
        created_at -> BigInt,
        database_storage_id -> Text,
        icon -> Text,
    }
}

diesel::table! {
    workspace_members_table (email, workspace_id) {
        email -> Text,
        role -> Integer,
        name -> Text,
        avatar_url -> Nullable<Text>,
        uid -> BigInt,
        workspace_id -> Text,
        updated_at -> Timestamp,
    }
}

diesel::allow_tables_to_appear_in_same_query!(
    chat_message_table,
    chat_table,
    collab_snapshot,
    user_data_migration_records,
    user_table,
    user_workspace_table,
    workspace_members_table,
);
