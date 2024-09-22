import { Table } from 'dexie';
import { ViewInfo } from '@/application/types';

export type ViewMeta = {
  publish_name: string;

  child_views: ViewInfo[];
  ancestor_views: ViewInfo[];

  visible_view_ids: string[];
  database_relations: Record<string, string>;
} & ViewInfo;

export type ViewMetasTable = {
  view_metas: Table<ViewMeta>;
};

export const viewMetasSchema = {
  view_metas: 'publish_name',
};
