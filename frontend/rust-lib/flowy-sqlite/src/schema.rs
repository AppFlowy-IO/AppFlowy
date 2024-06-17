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
    upload_file_part (upload_id, e_tag) {
        upload_id -> Text,
        e_tag -> Text,
        part_num -> Integer,
    }
}

diesel::table! {
    upload_file_table (upload_id) {
        upload_id -> Text,
        workspace_id -> Text,
        file_id -> Text,
        parent_dir -> Text,
        local_file_path -> Text,
        content_type -> Text,
        chunk_size -> Integer,
        num_chunk -> Integer,
        created_at -> BigInt,
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
    upload_file_part,
    upload_file_table,
    user_data_migration_records,
    user_table,
    user_workspace_table,
    workspace_members_table,
);
