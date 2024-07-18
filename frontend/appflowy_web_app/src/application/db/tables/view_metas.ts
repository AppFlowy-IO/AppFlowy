import { Table } from 'dexie';
import { PublishViewInfo } from '@/application/collab.type';

export type ViewMeta = {
  publish_name: string;

  child_views: PublishViewInfo[];
  ancestor_views: PublishViewInfo[];

  visible_view_ids: string[];
} & PublishViewInfo;

export type ViewMetasTable = {
  view_metas: Table<ViewMeta>;
};

export const viewMetasSchema = {
  view_metas: 'publish_name',
};
