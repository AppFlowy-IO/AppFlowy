import { CalendarLayoutPB, ViewLayoutPB, ViewPB } from '@/services/backend';

export type DatabaseViewLayout = ViewLayoutPB.Grid | ViewLayoutPB.Board | ViewLayoutPB.Calendar;

export interface DatabaseView {
  id: string;
  name: string;
  layout: DatabaseViewLayout;
}

export interface CalendarLayoutSetting {
  fieldId?: string;
  layoutTy?: CalendarLayoutPB;
  firstDayOfWeek?: number;
  showWeekends?: boolean;
  showWeekNumbers?: boolean;
}

export function pbToDatabaseView(viewPB: ViewPB): DatabaseView {
  return {
    id: viewPB.id,
    layout: viewPB.layout as DatabaseViewLayout,
    name: viewPB.name,
  };
}
