import { Filter } from '@/application/database-yjs';

export enum ChecklistFilterCondition {
  IsComplete = 0,
  IsIncomplete = 1,
}

export interface ChecklistFilter extends Filter {
  condition: ChecklistFilterCondition;
}
