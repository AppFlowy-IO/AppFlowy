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
CREATE OR REPLACE FUNCTION create_af_user_profile_trigger_func() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO af_user_profile (uid, uuid)
VALUES (NEW.uid, NEW.uuid);
RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER create_af_user_profile_trigger BEFORE
INSERT ON af_user FOR EACH ROW EXECUTE FUNCTION create_af_user_profile_trigger_func();
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
CREATE TRIGGER create_af_workspace_trigger BEFORE
INSERT ON af_user_profile FOR EACH ROW EXECUTE FUNCTION create_af_workspace_trigger_func();
-- collab table
CREATE TABLE IF NOT EXISTS af_collab (
   oid TEXT NOT NULL,
   name TEXT DEFAULT '',
   key BIGINT GENERATED ALWAYS AS IDENTITY,
   value BYTEA NOT NULL,
   value_size INTEGER,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (oid, key)
);
-- collab statistics table
CREATE TABLE IF NOT EXISTS af_collab_statistics (
   oid TEXT PRIMARY KEY,
   update_count BIGINT DEFAULT 0
);
-- collab statistics trigger
CREATE OR REPLACE FUNCTION increment_af_collab_update_count() RETURNS TRIGGER AS $$ BEGIN IF EXISTS(
      SELECT 1
      FROM af_collab_statistics
      WHERE oid = NEW.oid
   ) THEN
UPDATE af_collab_statistics
SET update_count = update_count + 1
WHERE oid = NEW.oid;
ELSE
INSERT INTO af_collab_statistics (oid, update_count)
VALUES (NEW.oid, 1);
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER af_collab_insert_trigger
AFTER
INSERT ON af_collab FOR EACH ROW EXECUTE FUNCTION increment_af_collab_update_count();
-- collab table full backup
CREATE TABLE IF NOT EXISTS af_collab_full_backup (
   key BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
   oid TEXT NOT NULL,
   name TEXT DEFAULT '',
   blob BYTEA NOT NULL,
   blob_size INTEGER NOT NULL,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);