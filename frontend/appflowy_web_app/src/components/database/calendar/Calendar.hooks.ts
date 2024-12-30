import { useCalendarEventsSelector, useCalendarLayoutSetting } from '@/application/database-yjs';
import { useCallback, useEffect, useMemo } from 'react';
import { dayjsLocalizer } from 'react-big-calendar';
import dayjs from 'dayjs';
import en from 'dayjs/locale/en';

export function useCalendarSetup() {
  const layoutSetting = useCalendarLayoutSetting();
  const { events, emptyEvents } = useCalendarEventsSelector();

  const dayPropGetter = useCallback((date: Date) => {
    const day = date.getDay();

    return {
      className: `day-${day}`,
    };
  }, []);

  useEffect(() => {
    dayjs.locale({
      ...en,
      weekStart: layoutSetting.firstDayOfWeek,
    });
  }, [layoutSetting]);

  const localizer = useMemo(() => dayjsLocalizer(dayjs), []);

  const formats = useMemo(() => {
    return {
      weekdayFormat: 'ddd',
    };
  }, []);

  return {
    localizer,
    formats,
    dayPropGetter,
    events,
    emptyEvents,
  };
}
