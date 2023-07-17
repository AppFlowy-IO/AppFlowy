DROP TABLE IF EXISTS af_user;
DROP TABLE IF EXISTS af_workspace;
DROP TABLE IF EXISTS af_user_profile;
DROP TABLE IF EXISTS af_collab;
DROP VIEW IF EXISTS af_collab_state;
DROP TABLE IF EXISTS af_collab_snapshot;
DROP TABLE IF EXISTS af_collab_statistics;

DROP TRIGGER IF EXISTS create_af_user_profile_trigger ON af_user_profile CASCADE;
DROP FUNCTION IF EXISTS create_af_user_profile_trigger_func;

DROP TRIGGER IF EXISTS create_af_workspace_trigger ON af_workspace CASCADE;
DROP FUNCTION IF EXISTS create_af_workspace_trigger_func;

DROP TRIGGER IF EXISTS af_collab_insert_trigger ON af_collab CASCADE;
DROP FUNCTION IF EXISTS increment_af_collab_update_count;

DROP TRIGGER IF EXISTS af_collab_snapshot_update_edit_count_trigger ON af_collab_snapshot;
DROP FUNCTION IF EXISTS af_collab_snapshot_update_edit_count;

DROP TRIGGER IF EXISTS check_and_delete_snapshots_trigger ON af_collab_snapshot CASCADE;
DROP FUNCTION IF EXISTS check_and_delete_snapshots;

DROP TRIGGER IF EXISTS new_af_collab_row_trigger ON af_collab CASCADE;
DROP FUNCTION IF EXISTS notify_on_insert_af_collab;

