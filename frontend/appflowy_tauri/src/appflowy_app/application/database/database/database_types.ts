import { DatabaseLayoutPB } from '@/services/backend';
import { Field, UndeterminedTypeOptionData } from '../field';
import { Filter } from '../filter';
import { GroupSetting, Group } from '../group';
import { RowMeta } from '../row';
import { Sort } from '../sort';
import { Cell } from '../cell';

export interface Database {
  id: string;
  isLinked: boolean;
  layoutType: DatabaseLayoutPB;
  fields: Field[];
  rowMetas: RowMeta[];
  filters: Filter[];
  sorts: Sort[];
  groupSettings: GroupSetting[];
  groups: Group[];
  typeOptions: Record<string, UndeterminedTypeOptionData>;
  cells: Record<string, Cell>;
}
