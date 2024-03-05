import React, { useMemo } from 'react';
import { DateFilterData } from '$app/application/database';
import { useTranslation } from 'react-i18next';
import dayjs from 'dayjs';
import { DateFilterConditionPB } from '@/services/backend';

function DateFilterValue({ data }: { data: DateFilterData }) {
  const { t } = useTranslation();

  const value = useMemo(() => {
    if (!data.timestamp) return '';

    let startStr = '';
    let endStr = '';

    if (data.start) {
      const end = data.end ?? data.start;
      const moreThanOneYear = dayjs.unix(end).diff(dayjs.unix(data.start), 'year') > 1;
      const format = moreThanOneYear ? 'MMM D, YYYY' : 'MMM D';

      startStr = dayjs.unix(data.start).format(format);
      endStr = dayjs.unix(end).format(format);
    }

    const timestamp = dayjs.unix(data.timestamp).format('MMM D');

    switch (data.condition) {
      case DateFilterConditionPB.DateIs:
        return `: ${timestamp}`;
      case DateFilterConditionPB.DateBefore:
        return `: ${t('grid.dateFilter.choicechipPrefix.before')} ${timestamp}`;
      case DateFilterConditionPB.DateAfter:
        return `: ${t('grid.dateFilter.choicechipPrefix.after')} ${timestamp}`;
      case DateFilterConditionPB.DateOnOrBefore:
        return `: ${t('grid.dateFilter.choicechipPrefix.onOrBefore')} ${timestamp}`;
      case DateFilterConditionPB.DateOnOrAfter:
        return `: ${t('grid.dateFilter.choicechipPrefix.onOrAfter')} ${timestamp}`;
      case DateFilterConditionPB.DateWithIn:
        return `: ${startStr} - ${endStr}`;
      case DateFilterConditionPB.DateIsEmpty:
        return `: ${t('grid.dateFilter.choicechipPrefix.isEmpty')}`;
      case DateFilterConditionPB.DateIsNotEmpty:
        return `: ${t('grid.dateFilter.choicechipPrefix.isNotEmpty')}`;
      default:
        return '';
    }
  }, [data, t]);

  return <>{value}</>;
}

export default DateFilterValue;
