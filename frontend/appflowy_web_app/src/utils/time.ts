import dayjs from 'dayjs';

export function renderDate(date: string, format: string, isUnix?: boolean): string {
  if (isUnix) return dayjs.unix(Number(date)).format(format);
  return dayjs(date).format(format);
}
