import { Table } from 'dexie';

export interface MetaData {
  view_id: string;
  name: string;
  icon: string | null;
  layout: number;
  extra: string | null;
  created_by: string | null;
  last_edited_by: string | null;
  last_edited_time: string;
  created_at: string;
}

export type ViewMeta = {
  publish_name: string;

  child_views: MetaData[];
  ancestor_views: MetaData[];
} & MetaData;

export type ViewMetasTable = {
  view_metas: Table<ViewMeta>;
};

export const viewMetasSchema = {
  view_metas: 'publish_name',
};
