import { Filter } from '@/application/database-yjs';

export enum TimeFormat {
  TwelveHour = 0,
  TwentyFourHour = 1,
}

export enum DateFormat {
  Local = 0,
  US = 1,
  ISO = 2,
  Friendly = 3,
  DayMonthYear = 4,
}

export enum DateFilterCondition {
  DateIs = 0,
  DateBefore = 1,
  DateAfter = 2,
  DateOnOrBefore = 3,
  DateOnOrAfter = 4,
  DateWithIn = 5,
  DateIsEmpty = 6,
  DateIsNotEmpty = 7,
}

export interface DateFilter extends Filter {
  condition: DateFilterCondition;
  start?: number;
  end?: number;
  timestamp?: number;
}
