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
INSERT INTO af_role_permissions (role_id, permission_id)
VALUES (
      (
         SELECT id
         FROM af_roles
         WHERE name = 'Owner'
      ),
      (
         SELECT id
         FROM af_permissions
         WHERE name = 'Full access'
      )
   ),
   (
      (
         SELECT id
         FROM af_roles
         WHERE name = 'Member'
      ),
      (
         SELECT id
         FROM af_permissions
         WHERE name = 'Read and write'
      )
   ),
   (
      (
         SELECT id
         FROM af_roles
         WHERE name = 'Guest'
      ),
      (
         SELECT id
         FROM af_permissions
         WHERE name = 'Read only'
      )
   );
-- user table
CREATE TABLE IF NOT EXISTS af_user (
   uuid UUID PRIMARY KEY,
   email TEXT NOT NULL DEFAULT '' UNIQUE,
   uid BIGSERIAL UNIQUE,
   name TEXT NOT NULL DEFAULT '',
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- af_workspace contains all the workspaces. Each workspace contains a list of members defined in af_workspace_member
CREATE TABLE IF NOT EXISTS af_workspace (
   workspace_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   database_storage_id UUID DEFAULT uuid_generate_v4(),
   owner_uid BIGINT,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   workspace_name TEXT DEFAULT 'My Workspace'
);
-- This trigger is fired before an insert operation on the af_user table. It automatically creates a workspace
-- in the af_workspace table with the uid of the new user profile as the owner_uid
CREATE OR REPLACE FUNCTION create_af_workspace_func() RETURNS TRIGGER AS $$BEGIN
INSERT INTO af_workspace (owner_uid)
VALUES (NEW.uid);
RETURN NEW;
END $$LANGUAGE plpgsql;
CREATE TRIGGER create_af_workspace_trigger BEFORE
INSERT ON af_user FOR EACH ROW EXECUTE FUNCTION create_af_workspace_func();
-- af_workspace_member contains all the members associated with a workspace and their roles.
CREATE TABLE IF NOT EXISTS af_workspace_member (
   uid BIGINT,
   role_id INT REFERENCES af_roles(id),
   workspace_id UUID REFERENCES af_workspace(workspace_id) ON DELETE CASCADE,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   UNIQUE(uid, workspace_id)
);
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
   owner_uid BIGINT,
   workspace_id UUID NOT NULL,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_af_collab_oid ON af_collab (oid);
-- This trigger will fire after an INSERT or UPDATE operation on af_collab_update. If the oid of the new or updated row
-- equals to a workspace_id in the af_workspace_member table, it will update the updated_at timestamp for the corresponding
-- row in the af_workspace_member table.
CREATE OR REPLACE FUNCTION update_af_workspace_member_updated_at_func() RETURNS TRIGGER AS $$ BEGIN IF (
      NEW.oid = (
         SELECT workspace_id
         FROM af_workspace_member
         WHERE workspace_id = NEW.oid
      )
   ) THEN
UPDATE af_workspace_member
SET updated_at = CURRENT_TIMESTAMP
WHERE workspace_id = NEW.oid;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER update_af_workspace_member_updated_at_trigger
AFTER
INSERT
   OR
UPDATE ON af_collab_update FOR EACH ROW EXECUTE PROCEDURE update_af_workspace_member_updated_at_func();
-- collab update table.
CREATE TABLE IF NOT EXISTS af_collab_update (
   oid TEXT REFERENCES af_collab(oid) ON DELETE CASCADE,
   name TEXT DEFAULT '',
   key BIGINT GENERATED ALWAYS AS IDENTITY,
   value BYTEA NOT NULL,
   value_size INTEGER,
   uid BIGINT NOT NULL,
   md5 TEXT DEFAULT '',
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   workspace_id UUID NOT NULL,
   PRIMARY KEY (oid, key)
);
-- This trigger is fired before an insert operation on the af_collab_update table. It checks if a corresponding collab
-- exists in the af_collab table. If not, it creates one with the oid, uid, and current timestamp. It might cause a
-- performance issue if the af_collab_update table is updated very frequently, especially if the af_collab table is large
-- and if the oid column isn't indexed
CREATE OR REPLACE FUNCTION insert_into_af_collab_if_not_exists() RETURNS TRIGGER AS $$ BEGIN IF NOT EXISTS (
      SELECT 1
      FROM af_collab
      WHERE oid = NEW.oid
   ) THEN
INSERT INTO af_collab (oid, owner_uid, created_at)
VALUES (NEW.oid, NEW.uid, CURRENT_TIMESTAMP);
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