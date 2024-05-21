import { DateFilter, DateFilterCondition } from '@/application/database-yjs';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import dayjs from 'dayjs';

function DateFilterContentOverview({ filter }: { filter: DateFilter }) {
  const { t } = useTranslation();

  const value = useMemo(() => {
    if (!filter.timestamp) return '';

    let startStr = '';
    let endStr = '';

    if (filter.start) {
      const end = filter.end ?? filter.start;
      const moreThanOneYear = dayjs.unix(end).diff(dayjs.unix(filter.start), 'year') > 1;
      const format = moreThanOneYear ? 'MMM D, YYYY' : 'MMM D';

      startStr = dayjs.unix(filter.start).format(format);
      endStr = dayjs.unix(end).format(format);
    }

    const timestamp = dayjs.unix(filter.timestamp).format('MMM D');

    switch (filter.condition) {
      case DateFilterCondition.DateIs:
        return `: ${timestamp}`;
      case DateFilterCondition.DateBefore:
        return `: ${t('grid.dateFilter.choicechipPrefix.before')} ${timestamp}`;
      case DateFilterCondition.DateAfter:
        return `: ${t('grid.dateFilter.choicechipPrefix.after')} ${timestamp}`;
      case DateFilterCondition.DateOnOrBefore:
        return `: ${t('grid.dateFilter.choicechipPrefix.onOrBefore')} ${timestamp}`;
      case DateFilterCondition.DateOnOrAfter:
        return `: ${t('grid.dateFilter.choicechipPrefix.onOrAfter')} ${timestamp}`;
      case DateFilterCondition.DateWithIn:
        return `: ${startStr} - ${endStr}`;
      case DateFilterCondition.DateIsEmpty:
        return `: ${t('grid.dateFilter.choicechipPrefix.isEmpty')}`;
      case DateFilterCondition.DateIsNotEmpty:
        return `: ${t('grid.dateFilter.choicechipPrefix.isNotEmpty')}`;
      default:
        return '';
    }
  }, [filter, t]);

  return <>{value}</>;
}

export default DateFilterContentOverview;
