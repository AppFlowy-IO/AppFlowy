import dayjs from 'dayjs';

export enum DateFormat {
  Date = 'MMM D, YYYY',
  DateTime = 'MMM D, YYYY h:mm A',
}

export function renderDate(date: string, format: DateFormat = DateFormat.Date): string {
  return dayjs(date).format(format);
}
