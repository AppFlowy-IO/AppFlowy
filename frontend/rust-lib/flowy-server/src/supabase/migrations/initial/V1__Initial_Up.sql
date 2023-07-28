-- Insert default roles
CREATE TABLE IF NOT EXISTS af_roles (
   id SERIAL PRIMARY KEY,
   name TEXT UNIQUE NOT NULL
);
INSERT INTO af_roles (name)
VALUES ('Owner'),
   ('Member'),
   ('Guest');
CREATE TABLE af_permissions (
   id SERIAL PRIMARY KEY,
   name VARCHAR(255) UNIQUE NOT NULL,
   access_level INTEGER,
   description TEXT
);
-- Insert default permissions
INSERT INTO af_permissions (name, description, access_level)
VALUES ('Read only', 'Can read', 10),
   (
      'Read and comment',
      'Can read and comment, but not edit',
      20
   ),
   (
      'Read and write',
      'Can read and edit, but not share with others',
      30
   ),
   (
      'Full access',
      'Can edit and share with others',
      50
   );
-- Represents a permission that a role has. The list of all permissions a role has can be obtained by querying this table for all rows with a given role_id.
CREATE TABLE af_role_permissions (
   role_id INT REFERENCES af_roles(id),
   permission_id INT REFERENCES af_permissions(id),
   PRIMARY KEY (role_id, permission_id)
);
-- Associate permissions with roles
WITH role_ids AS (
   SELECT id,
      name
   FROM af_roles
   WHERE name IN ('Owner', 'Member', 'Guest')
),
permission_ids AS (
   SELECT id,
      name
   FROM af_permissions
   WHERE name IN ('Full access', 'Read and write', 'Read only')
)
INSERT INTO af_role_permissions (role_id, permission_id)
SELECT r.id,
   p.id
FROM role_ids r
   CROSS JOIN permission_ids p
WHERE (
      r.name = 'Owner'
      AND p.name = 'Full access'
   )
   OR (
      r.name = 'Member'
      AND p.name = 'Read and write'
   )
   OR (
      r.name = 'Guest'
      AND p.name = 'Read only'
   );
-- user table
CREATE TABLE IF NOT EXISTS af_user (
   uuid UUID PRIMARY KEY,
   email TEXT NOT NULL DEFAULT '' UNIQUE,
   uid BIGSERIAL UNIQUE,
   name TEXT NOT NULL DEFAULT '',
   deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
   updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE OR REPLACE FUNCTION update_updated_at_column_func() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW();
RETURN NEW;
END;
$$ language 'plpgsql';
CREATE TRIGGER update_af_user_modtime BEFORE
UPDATE ON af_user FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column_func();
-- af_workspace contains all the workspaces. Each workspace contains a list of members defined in af_workspace_member
CREATE TABLE IF NOT EXISTS af_workspace (
   workspace_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   database_storage_id UUID DEFAULT uuid_generate_v4(),
   owner_uid BIGINT REFERENCES af_user(uid) ON DELETE CASCADE,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   -- 0: Free
   workspace_type INTEGER NOT NULL DEFAULT 0,
   deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
   workspace_name TEXT DEFAULT 'My Workspace'
);
-- This trigger is fired after an insert operation on the af_user table. It automatically creates a workspace
-- in the af_workspace table with the uid of the new user profile as the owner_uid
CREATE OR REPLACE FUNCTION create_af_workspace_func() RETURNS TRIGGER AS $$BEGIN
INSERT INTO af_workspace (owner_uid)
VALUES (NEW.uid);
RETURN NEW;
END $$LANGUAGE plpgsql;
CREATE TRIGGER create_af_workspace_trigger
AFTER
INSERT ON af_user FOR EACH ROW EXECUTE FUNCTION create_af_workspace_func();
-- af_workspace_member contains all the members associated with a workspace and their roles.
CREATE TABLE IF NOT EXISTS af_workspace_member (
   uid BIGINT NOT NULL,
   role_id INT NOT NULL REFERENCES af_roles(id),
   workspace_id UUID NOT NULL REFERENCES af_workspace(workspace_id) ON DELETE CASCADE,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   UNIQUE(uid, workspace_id)
);
CREATE UNIQUE INDEX idx_af_workspace_member ON af_workspace_member (uid, workspace_id, role_id);
-- This trigger is fired after an insert operation on the af_workspace table. It automatically creates a workspace
-- member in the af_workspace_member table. If the user is the owner of the workspace, they are given the role 'Owner'.
CREATE OR REPLACE FUNCTION manage_af_workspace_member_role_func() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO af_workspace_member (uid, role_id, workspace_id)
VALUES (
      NEW.owner_uid,
      (
         SELECT id
         FROM af_roles
         WHERE name = 'Owner'
      ),
      NEW.workspace_id
   ) ON CONFLICT (uid, workspace_id) DO
UPDATE
SET role_id = EXCLUDED.role_id;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER manage_af_workspace_member_role_trigger
AFTER
INSERT ON af_workspace FOR EACH ROW EXECUTE FUNCTION manage_af_workspace_member_role_func();
-- af_user_profile_view is a view that contains all the user profiles and their latest workspace_id.
-- a subquery is first used to find the workspace_id of the workspace with the latest updated_at timestamp for each
-- user. This subquery is then joined with the af_user table to create the view. Note that a LEFT JOIN is used in
-- case there are users without workspaces, in which case latest_workspace_id will be NULL for those users.
CREATE OR REPLACE VIEW af_user_profile_view AS
SELECT u.*,
   w.workspace_id AS latest_workspace_id
FROM af_user u
   INNER JOIN (
      SELECT uid,
         workspace_id,
         rank() OVER (
            PARTITION BY uid
            ORDER BY updated_at DESC
         ) AS rn
      FROM af_workspace_member
   ) w ON u.uid = w.uid
   AND w.rn = 1;
-- af_collab contains all the collabs.
CREATE TABLE IF NOT EXISTS af_collab(
   oid TEXT PRIMARY KEY,
   owner_uid BIGINT NOT NULL,
   workspace_id UUID NOT NULL REFERENCES af_workspace(workspace_id) ON DELETE CASCADE,
   -- 0: Private, 1: Shared
   access_level INTEGER NOT NULL DEFAULT 0,
   deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX idx_af_collab_oid ON af_collab (oid);
-- collab update table.
CREATE TABLE IF NOT EXISTS af_collab_update (
   oid TEXT REFERENCES af_collab(oid) ON DELETE CASCADE,
   key BIGSERIAL,
   value BYTEA NOT NULL,
   value_size INTEGER,
   partition_key INTEGER NOT NULL,
   uid BIGINT NOT NULL,
   md5 TEXT DEFAULT '',
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   workspace_id UUID NOT NULL REFERENCES af_workspace(workspace_id) ON DELETE CASCADE,
   PRIMARY KEY (oid, key, partition_key)
) PARTITION BY LIST (partition_key);
CREATE TABLE af_collab_update_document PARTITION OF af_collab_update FOR
VALUES IN (0);
CREATE TABLE af_collab_update_database PARTITION OF af_collab_update FOR
VALUES IN (1);
CREATE TABLE af_collab_update_w_database PARTITION OF af_collab_update FOR
VALUES IN (2);
CREATE TABLE af_collab_update_folder PARTITION OF af_collab_update FOR
VALUES IN (3);
CREATE TABLE af_collab_update_database_row PARTITION OF af_collab_update FOR
VALUES IN (4);
-- This trigger will fire after an INSERT or UPDATE operation on af_collab_update. If the oid of the new or updated row
-- equals to a workspace_id in the af_workspace_member table, it will update the updated_at timestamp for the corresponding
-- row in the af_workspace_member table.
CREATE OR REPLACE FUNCTION update_af_workspace_member_updated_at_func() RETURNS TRIGGER AS $$ BEGIN IF EXISTS (
      SELECT 1
      FROM af_workspace_member
      WHERE workspace_id::TEXT = NEW.oid
   ) THEN
UPDATE af_workspace_member
SET updated_at = CURRENT_TIMESTAMP
WHERE workspace_id::TEXT = NEW.oid
   AND uid = NEW.uid;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER update_af_workspace_member_updated_at_trigger
AFTER
INSERT
   OR
UPDATE ON af_collab_update_folder FOR EACH ROW EXECUTE PROCEDURE update_af_workspace_member_updated_at_func();
-- This trigger is fired before an insert operation on the af_collab_update table. It checks if a corresponding collab
-- exists in the af_collab table. If not, it creates one with the oid, uid, and current timestamp. It might cause a
-- performance issue if the af_collab_update table is updated very frequently, especially if the af_collab table is large
-- and if the oid column isn't indexed
CREATE OR REPLACE FUNCTION insert_into_af_collab_if_not_exists() RETURNS TRIGGER AS $$ BEGIN IF NOT EXISTS (
      SELECT 1
      FROM af_collab
      WHERE oid = NEW.oid
   ) THEN
INSERT INTO af_collab (oid, owner_uid, workspace_id, created_at)
VALUES (
      NEW.oid,
      NEW.uid,
      NEW.workspace_id,
      CURRENT_TIMESTAMP
   );
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER insert_into_af_collab_trigger BEFORE
INSERT ON af_collab_update FOR EACH ROW EXECUTE FUNCTION insert_into_af_collab_if_not_exists();
CREATE TABLE af_collab_member (
   uid BIGINT REFERENCES af_user(uid) ON DELETE CASCADE,
   oid TEXT REFERENCES af_collab(oid) ON DELETE CASCADE,
   role_id INTEGER REFERENCES af_roles(id),
   PRIMARY KEY(uid, oid)
);
-- This trigger is fired after an insert operation on the af_collab table. It automatically adds the collab's owner
-- to the af_collab_member table with the role 'Owner'.
CREATE OR REPLACE FUNCTION insert_into_af_collab_member() RETURNS TRIGGER AS $$ BEGIN
INSERT INTO af_collab_member (oid, uid, role_id)
VALUES (
      NEW.oid,
      NEW.owner_uid,
      (
         SELECT id
         FROM af_roles
         WHERE name = 'Owner'
      )
   );
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER insert_into_af_collab_member_trigger
AFTER
INSERT ON af_collab FOR EACH ROW EXECUTE FUNCTION insert_into_af_collab_member();
-- collab statistics. It will be used to store the edit_count of the collab.
CREATE TABLE IF NOT EXISTS af_collab_statistics (
   oid TEXT PRIMARY KEY,
   edit_count BIGINT NOT NULL DEFAULT 0
);
-- This trigger is fired after an insert operation on the af_collab_update table. It increments the edit_count of the
-- corresponding collab in the af_collab_statistics table. If the collab doesn't exist in the af_collab_statistics table,
-- it creates one with edit_count set to 1.
CREATE OR REPLACE FUNCTION increment_af_collab_edit_count() RETURNS TRIGGER AS $$BEGIN IF EXISTS(
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
$$LANGUAGE plpgsql;
CREATE TRIGGER af_collab_update_edit_count_trigger
AFTER
INSERT ON af_collab_update FOR EACH ROW EXECUTE FUNCTION increment_af_collab_edit_count();
-- collab snapshot. It will be used to store the snapshots of the collab.
CREATE TABLE IF NOT EXISTS af_collab_snapshot (
   sid BIGSERIAL PRIMARY KEY,
   oid TEXT NOT NULL,
   name TEXT DEFAULT '',
   blob BYTEA NOT NULL,
   blob_size INTEGER NOT NULL,
   edit_count BIGINT NOT NULL DEFAULT 0,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- This trigger is fired after an insert operation on the af_collab_snapshot table. It automatically sets the edit_count
-- of the new snapshot to the current edit_count of the collab in the af_collab_statistics table.
CREATE OR REPLACE FUNCTION af_collab_snapshot_update_edit_count() RETURNS TRIGGER AS $$BEGIN NEW.edit_count := (
      SELECT COALESCE(edit_count, 0)
      FROM af_collab_statistics
      WHERE oid = NEW.oid
   );
RETURN NEW;
END;
$$LANGUAGE plpgsql;
CREATE TRIGGER af_collab_snapshot_update_edit_count_trigger
AFTER
INSERT ON af_collab_snapshot FOR EACH ROW EXECUTE FUNCTION af_collab_snapshot_update_edit_count();
-- collab state view. It will be used to get the current state of the collab.
CREATE VIEW af_collab_state AS
SELECT a.oid,
   a.created_at AS snapshot_created_at,
   a.edit_count AS snapshot_edit_count,
   b.edit_count AS current_edit_count
FROM af_collab_snapshot AS a
   JOIN af_collab_statistics AS b ON a.oid = b.oid;
-- Insert a workspace member if the user with given uid is the owner of the workspace
CREATE OR REPLACE FUNCTION insert_af_workspace_member_if_owner(
      p_uid BIGINT,
      p_role_id INT,
      p_workspace_id UUID
   ) RETURNS VOID AS $$ BEGIN -- If user is the owner, proceed with the insert operation
INSERT INTO af_workspace_member (uid, role_id, workspace_id)
SELECT p_uid,
   p_role_id,
   p_workspace_id
FROM af_workspace
WHERE workspace_id = p_workspace_id
   AND owner_uid = p_uid;
-- Check if the insert operation was successful. If not, user is not the owner of the workspace.
IF NOT FOUND THEN RAISE EXCEPTION 'Unsupported operation: User is not the owner of the workspace.';
END IF;
END;
$$ LANGUAGE plpgsql;
-- show the shared documents and databases for the given uid
CREATE OR REPLACE FUNCTION af_shared_collab_for_uid(_uid BIGINT) RETURNS TABLE (
      oid TEXT,
      owner_uid BIGINT,
      workspace_id UUID,
      access_level INTEGER,
      created_at TIMESTAMP WITH TIME ZONE
   ) AS $$ BEGIN RETURN QUERY
SELECT c.*
FROM af_collab c
   JOIN af_collab_member cm ON c.oid = cm.oid
   JOIN af_workspace_member wm ON c.workspace_id = wm.workspace_id
WHERE cm.uid = _uid
   AND c.owner_uid != _uid;
END;
$$ LANGUAGE plpgsql;
-- Flush the collab updates
CREATE OR REPLACE FUNCTION public.flush_collab_updates(
      oid TEXT,
      new_key BIGINT,
      new_value BYTEA,
      md5 TEXT,
      value_size INTEGER,
      partition_key INTEGER,
      uid BIGINT,
      workspace_id UUID,
      removed_keys BIGINT []
   ) RETURNS void AS $$
DECLARE lock_key INTEGER;
BEGIN -- Hashing the oid to an integer for the advisory lock
lock_key := (hashtext(oid)::bigint)::integer;
-- Getting a session level lock
PERFORM pg_advisory_lock(lock_key);
-- Deleting rows with keys in removed_keys
DELETE FROM af_collab_update
WHERE key = ANY (removed_keys);
-- Inserting a new update with the new key and value
INSERT INTO af_collab_update(
      oid,
      key,
      value,
      md5,
      value_size,
      partition_key,
      uid,
      workspace_id
   )
VALUES (
      oid,
      new_key,
      new_value,
      md5,
      value_size,
      partition_key,
      uid,
      workspace_id
   );
-- Releasing the lock
PERFORM pg_advisory_unlock(lock_key);
RETURN;
END;
$$ LANGUAGE plpgsql;