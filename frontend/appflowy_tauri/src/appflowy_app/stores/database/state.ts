import { proxy } from 'valtio';
import { Database } from '$app/interfaces/database';
import { DatabaseLayoutPB } from '@/services/backend';

export const database = proxy<Database>({
  id: '',
  name: '',
  fields: [],
  rows: [],
  layoutType: DatabaseLayoutPB.Grid,
  layoutSetting: {},
  isLinked: false,
});
