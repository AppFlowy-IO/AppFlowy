import { TimeFormat, DateFormat } from '@/application/database-yjs';

export function getTimeFormat(timeFormat?: TimeFormat) {
  switch (timeFormat) {
    case TimeFormat.TwelveHour:
      return 'h:mm A';
    case TimeFormat.TwentyFourHour:
      return 'HH:mm';
    default:
      return 'HH:mm';
  }
}

export function getDateFormat(dateFormat?: DateFormat) {
  switch (dateFormat) {
    case DateFormat.Friendly:
      return 'MMM DD, YYYY';
    case DateFormat.ISO:
      return 'YYYY-MM-DD';
    case DateFormat.US:
      return 'YYYY/MM/DD';
    case DateFormat.Local:
      return 'MM/DD/YYYY';
    case DateFormat.DayMonthYear:
      return 'DD/MM/YYYY';
    default:
      return 'YYYY-MM-DD';
  }
}
