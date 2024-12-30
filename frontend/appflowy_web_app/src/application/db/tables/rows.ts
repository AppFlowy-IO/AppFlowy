import { Table } from 'dexie';

export type rowTable = {
  rows: Table<{
    row_id: string;
    row_key: string;
    version: number;
  }>;
};

export const rowSchema = {
  rows: 'row_key',
};