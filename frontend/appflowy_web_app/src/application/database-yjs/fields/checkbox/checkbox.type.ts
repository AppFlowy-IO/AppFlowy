import { Filter } from '@/application/database-yjs';

export enum CheckboxFilterCondition {
  IsChecked = 0,
  IsUnChecked = 1,
}

export interface CheckboxFilter extends Filter {
  condition: CheckboxFilterCondition;
}
