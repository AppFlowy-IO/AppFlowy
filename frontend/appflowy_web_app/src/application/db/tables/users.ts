import { User } from '@/application/types';
import { Table } from 'dexie';

export type UserTable = {
  users: Table<User>;
};

export const userSchema = {
  users: 'uuid',
};