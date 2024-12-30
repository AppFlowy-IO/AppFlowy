import { Filter } from '@/application/database-yjs';

export enum TextFilterCondition {
  TextIs = 0,
  TextIsNot = 1,
  TextContains = 2,
  TextDoesNotContain = 3,
  TextStartsWith = 4,
  TextEndsWith = 5,
  TextIsEmpty = 6,
  TextIsNotEmpty = 7,
}

export interface TextFilter extends Filter {
  condition: TextFilterCondition;
  content: string;
}
