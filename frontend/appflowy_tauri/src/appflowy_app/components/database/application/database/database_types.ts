import { DatabaseLayoutPB } from '@/services/backend';
import { Field } from '../field';
import { Filter } from '../filter';
import { GroupSetting, Group } from '../group';
import { RowMeta } from '../row';
import { Sort } from '../sort';

export interface Database {
  id: string;
  isLinked: boolean;
  layoutType: DatabaseLayoutPB,
  fields: Field[];
  rowMetas: RowMeta[];
  filters: Filter[];
  sorts: Sort[];
  groupSettings: GroupSetting[];
  groups: Group[];
}
