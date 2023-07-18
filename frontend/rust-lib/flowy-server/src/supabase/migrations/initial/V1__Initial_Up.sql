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
   email TEXT DEFAULT '',
   uid BIGSERIAL UNIQUE,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- user profile table
CREATE TABLE IF NOT EXISTS af_user_profile (
   uid BIGINT PRIMARY KEY,
   uuid UUID,
   name TEXT,
   email TEXT,
   workspace_id UUID DEFAULT uuid_generate_v4(),
   FOREIGN KEY (uid) REFERENCES af_user(uid) ON DELETE CASCADE
);
-- This create_af_user_profile_trigger trigger is fired after an insert operation on the af_user table. It automatically creates a
-- corresponding user profile in the af_user_profile table with the same uid, uuid, and email
CREATE OR REPLACE FUNCTION create_af_user_profile_trigger_func() RETURNS TRIGGER AS $$BEGIN
INSERT INTO af_user_profile (uid, uuid, email)
VALUES (NEW.uid, NEW.uuid, NEW.email);
RETURN NEW;
END $$LANGUAGE plpgsql;
CREATE TRIGGER create_af_user_profile_trigger
AFTER
INSERT ON af_user FOR EACH ROW EXECUTE FUNCTION create_af_user_profile_trigger_func();
-- workspace table
CREATE TABLE IF NOT EXISTS af_workspace (
   workspace_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   owner_uid BIGINT,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   workspace_name TEXT DEFAULT 'My Workspace'
);
-- This trigger is fired before an insert operation on the af_user_profile table. It automatically creates a workspace
-- in the af_workspace table with the uid of the new user profile as the owner_uid and the workspace_id from the new
-- user profile.
CREATE OR REPLACE FUNCTION create_af_workspace_trigger_func() RETURNS TRIGGER AS $$BEGIN
INSERT INTO af_workspace (owner_uid, workspace_id)
VALUES (NEW.uid, NEW.workspace_id);
RETURN NEW;
END $$LANGUAGE plpgsql;
CREATE TRIGGER create_af_workspace_trigger BEFORE
INSERT ON af_user_profile FOR EACH ROW EXECUTE FUNCTION create_af_workspace_trigger_func();
-- af_workspace_member contains all the members associated with a workspace and their roles.
CREATE TABLE IF NOT EXISTS af_workspace_member (
   uid BIGINT,
   role_id INT REFERENCES af_roles(id),
   workspace_id UUID REFERENCES af_workspace(workspace_id) ON DELETE CASCADE,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
   UNIQUE(uid, workspace_id)
);
-- This trigger is fired after an insert operation on the af_user_profile table. It automatically creates a workspace
-- member in the af_workspace_member table. If the user is the owner of the workspace, they are given the role 'Owner'.
-- Otherwise, they are given the role 'Member'. If a member with the same uid and workspace_id already exists, their
-- role is updated.
CREATE OR REPLACE FUNCTION manage_af_workspace_member_role_trigger_func() RETURNS TRIGGER AS $$ BEGIN -- For new user profile, set as owner if user is the owner of the workspace, else set as member
INSERT INTO af_workspace_member (uid, role_id, workspace_id)
VALUES (
      NEW.uid,
      (
         SELECT id
         FROM af_roles
         WHERE name = (
               CASE
                  WHEN NEW.uid IN (
                     SELECT owner_uid
                     FROM af_workspace
                     WHERE workspace_id = NEW.workspace_id
                  ) THEN 'Owner'
                  ELSE 'Member'
               END
            )
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
INSERT ON af_user_profile FOR EACH ROW EXECUTE FUNCTION manage_af_workspace_member_role_trigger_func();
CREATE TABLE IF NOT EXISTS af_collab(
   oid TEXT PRIMARY KEY,
   owner_uid BIGINT,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_af_collab_oid ON af_collab (oid);
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
   uid BIGINT REFERENCES af_user(uid),
   oid TEXT REFERENCES af_collab(oid),
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