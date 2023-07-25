![](./schema.png)

1. `af_roles` table: This table contains a list of roles that are used in your application, such as 'Owner', 'Member', and 'Guest'.

2. `af_permissions` table: This table stores permissions that are used in your application. Each permission has a name, a description, and an access level.

3. `af_role_permissions` table: This is a many-to-many relation table between roles and permissions. It represents which permissions a role has.

4. `af_user` table: This stores the details of users like uuid, email, uid, name, created_at. Here, uid is an auto-incrementing integer that uniquely identifies a user.

5. `af_workspace` table: This table contains all the workspaces. Each workspace has an owner which is associated with the uid of a user in the `af_user` table.

6. `af_workspace_member` table: This table maintains a list of all the members associated with a workspace and their roles.

7. `af_collab` and `af_collab_member` tables: These tables store the collaborations and their members respectively. Each collaboration has an owner and a workspace associated with it.

8. `af_collab_update`, `af_collab_update_document`, `af_collab_update_database`, `af_collab_update_w_database`, `af_collab_update_folder`, `af_database_row_update` tables: These tables are used for handling updates to collaborations.

9. `af_collab_statistics`, `af_collab_snapshot`, `af_collab_state`: These tables and view are used for maintaining statistics and snapshots of collaborations.

10. `af_user_profile_view` view: This view is used to get the latest workspace_id for each user.
