import { Table } from 'dexie';
import { UserProfile } from '@/application/user.type';

export type UsersTable = {
  users: Table<UserProfile>;
};

export const usersSchema = {
  users: 'uuid, uid, email, name, workspaceId, iconUrl',
};