-- user table
CREATE TABLE IF NOT EXISTS af_user (
   uuid UUID PRIMARY KEY,
   uid BIGINT GENERATED ALWAYS AS IDENTITY,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- user profile table
CREATE TABLE IF NOT EXISTS af_user_profile (
   uid BIGINT PRIMARY KEY,
   uuid UUID,
   name TEXT,
   email TEXT,
   workspace_id UUID DEFAULT uuid_generate_v4()
);
-- user_profile trigger
CREATE OR REPLACE FUNCTION create_user_profile_trigger_func() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO af_user_profile (uid, uuid)
VALUES (NEW.uid, NEW.uuid);
RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER create_af_user_profile_trigger
AFTER
INSERT ON af_user FOR EACH ROW EXECUTE FUNCTION create_user_profile_trigger_func();
-- workspace table
CREATE TABLE IF NOT EXISTS af_workspace (
   workspace_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   uid BIGINT,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   workspace_name TEXT DEFAULT 'My Workspace'
);
-- workspace  trigger
CREATE OR REPLACE FUNCTION create_af_workspace_trigger_func() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO af_workspace (uid, workspace_id)
VALUES (NEW.uid, NEW.workspace_id);
RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER create_af_workspace_trigger
AFTER
INSERT ON af_user_profile FOR EACH ROW EXECUTE FUNCTION create_af_workspace_trigger_func();
-- collab table
CREATE TABLE IF NOT EXISTS af_collab (
   oid TEXT,
   key BIGINT GENERATED ALWAYS AS IDENTITY,
   value TEXT NOT NULL,
   PRIMARY KEY (oid, key)
);