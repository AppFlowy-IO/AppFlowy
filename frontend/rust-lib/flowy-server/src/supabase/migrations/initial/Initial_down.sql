DROP TABLE IF EXISTS af_user;
DROP TABLE IF EXISTS af_workspace;
DROP TABLE IF EXISTS af_user_profile;
DROP TABLE IF EXISTS af_collab;
DROP TABLE IF EXISTS af_collab_full_backup;
DROP TABLE IF EXISTS af_collab_statistics;

DROP TRIGGER IF EXISTS create_af_user_profile_trigger ON af_user_profile CASCADE;
DROP FUNCTION IF EXISTS create_af_user_profile_trigger_func;

DROP TRIGGER IF EXISTS create_af_workspace_trigger ON af_workspace CASCADE;
DROP FUNCTION IF EXISTS create_af_workspace_trigger_func;

DROP TRIGGER IF EXISTS af_collab_insert_trigger ON af_collab CASCADE;
DROP FUNCTION IF EXISTS increment_af_collab_update_count;
