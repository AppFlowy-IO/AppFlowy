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
-- collab table.
CREATE TABLE IF NOT EXISTS af_collab (
   oid TEXT NOT NULL,
   name TEXT DEFAULT '',
   key BIGINT GENERATED ALWAYS AS IDENTITY,
   value BYTEA NOT NULL,
   value_size INTEGER,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (oid, key)
);
-- collab statistics. It will be used to store the edit_count of the collab.
CREATE TABLE IF NOT EXISTS af_collab_statistics (
   oid TEXT PRIMARY KEY,
   edit_count BIGINT DEFAULT 0
);
-- collab statistics trigger. It will increment the edit_count of the collab when a new row is inserted in the af_collab table.
CREATE OR REPLACE FUNCTION increment_af_collab_edit_count() RETURNS TRIGGER AS $$ BEGIN IF EXISTS(
      SELECT 1
      FROM af_collab_statistics
      WHERE oid = NEW.oid
   ) THEN
UPDATE af_collab_statistics
SET edit_count = edit_count + 1
WHERE oid = NEW.oid;
ELSE
INSERT INTO af_collab_statistics (oid, edit_count)
VALUES (NEW.oid, 1);
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER af_collab_insert_trigger
AFTER
INSERT ON af_collab FOR EACH ROW EXECUTE FUNCTION increment_af_collab_edit_count();
-- collab snapshot. It will be used to store the snapshots of the collab.
CREATE TABLE IF NOT EXISTS af_collab_snapshot (
   sid BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
   oid TEXT NOT NULL,
   name TEXT DEFAULT '',
   blob BYTEA NOT NULL,
   blob_size INTEGER NOT NULL,
   edit_count BIGINT DEFAULT 0,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- auto insert edit_count in the snapshot table.
CREATE OR REPLACE FUNCTION af_collab_snapshot_update_edit_count() RETURNS TRIGGER AS $$ BEGIN NEW.edit_count := (
      SELECT edit_count
      FROM af_collab_statistics
      WHERE oid = NEW.oid
   );
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER af_collab_snapshot_update_edit_count_trigger BEFORE
INSERT ON af_collab_snapshot FOR EACH ROW EXECUTE FUNCTION af_collab_snapshot_update_edit_count();
-- collab snapshot trigger. It will delete the oldest snapshot if the number of snapshots is greater than 20.
-- It can use the PG_CRON extension to run this trigger periodically.
CREATE OR REPLACE FUNCTION check_and_delete_snapshots() RETURNS TRIGGER AS $$
DECLARE row_count INT;
BEGIN
SELECT COUNT(*) INTO row_count
FROM af_collab_snapshot
WHERE oid = NEW.oid;
IF row_count > 20 THEN
DELETE FROM af_collab_snapshot
WHERE id IN (
      SELECT id
      FROM af_collab_snapshot
      WHERE created_at < NOW() - INTERVAL '10 days'
         AND oid = NEW.oid
      ORDER BY created_at ASC
      LIMIT row_count - 20
   );
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER check_and_delete_snapshots_trigger
AFTER
INSERT
   OR
UPDATE ON af_collab_snapshot FOR EACH ROW EXECUTE FUNCTION check_and_delete_snapshots();
-- collab state view. It will be used to get the current state of the collab.
CREATE VIEW af_collab_state AS
SELECT a.oid,
   a.created_at AS snapshot_created_at,
   a.edit_count AS snapshot_edit_count,
   b.edit_count AS current_edit_count
FROM af_collab_snapshot AS a
   JOIN af_collab_statistics AS b ON a.oid = b.oid;