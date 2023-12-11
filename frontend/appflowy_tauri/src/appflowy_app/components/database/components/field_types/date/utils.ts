import { DateFormatPB, TimeFormatPB } from '@/services/backend';

export function getTimeFormat(timeFormat?: TimeFormatPB) {
  switch (timeFormat) {
    case TimeFormatPB.TwelveHour:
      return 'h:mm A';
    case TimeFormatPB.TwentyFourHour:
      return 'HH:mm';
    default:
      return 'HH:mm';
  }
}

export function getDateFormat(dateFormat?: DateFormatPB) {
  switch (dateFormat) {
    case DateFormatPB.Friendly:
      return 'MMM DD, YYYY';
    case DateFormatPB.ISO:
      return 'YYYY-MMM-DD';
    case DateFormatPB.US:
      return 'YYYY/MMM/DD';
    case DateFormatPB.Local:
      return 'MMM/DD/YYYY';
    case DateFormatPB.DayMonthYear:
      return 'DD/MMM/YYYY';
    default:
      return 'YYYY-MMM-DD';
  }
}
