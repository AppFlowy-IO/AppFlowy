import React, { useMemo } from 'react';
import { DateFilter as DateFilterType, DateFilterData, Field } from '$app/components/database/application';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';
import { DateFilterConditionPB } from '@/services/backend';
import DateSet from '$app/components/database/components/field_types/date/DateSet';
import { OutlinedInput } from '@mui/material';
import dayjs from 'dayjs';

interface Props {
  filter: DateFilterType;
  field: Field;
  onChange: (filterData: DateFilterData) => void;
}

function DateFilter({ filter, field, onChange }: Props) {
  const { t } = useTranslation();
  const showCalendar =
    filter.data.condition !== DateFilterConditionPB.DateIsEmpty &&
    filter.data.condition !== DateFilterConditionPB.DateIsNotEmpty;

  const conditions = useMemo(() => {
    return [
      {
        value: DateFilterConditionPB.DateIs,
        text: t('grid.dateFilter.is'),
      },
      {
        value: DateFilterConditionPB.DateBefore,
        text: t('grid.dateFilter.before'),
      },
      {
        value: DateFilterConditionPB.DateAfter,
        text: t('grid.dateFilter.after'),
      },
      {
        value: DateFilterConditionPB.DateOnOrBefore,
        text: t('grid.dateFilter.onOrBefore'),
      },
      {
        value: DateFilterConditionPB.DateOnOrAfter,
        text: t('grid.dateFilter.onOrAfter'),
      },
      {
        value: DateFilterConditionPB.DateWithIn,
        text: t('grid.dateFilter.between'),
      },
      {
        value: DateFilterConditionPB.DateIsEmpty,
        text: t('grid.dateFilter.empty'),
      },
      {
        value: DateFilterConditionPB.DateIsNotEmpty,
        text: t('grid.dateFilter.notEmpty'),
      },
    ];
  }, [t]);

  const condition = filter.data.condition;
  const isRange = condition === DateFilterConditionPB.DateWithIn;
  const timestamp = useMemo(() => {
    const now = Date.now() / 1000;

    if (isRange) {
      return filter.data.start ? filter.data.start : now;
    }

    return filter.data.timestamp ? filter.data.timestamp : now;
  }, [filter.data.start, filter.data.timestamp, isRange]);

  const endTimestamp = useMemo(() => {
    const now = Date.now() / 1000;

    if (isRange) {
      return filter.data.end ? filter.data.end : now;
    }

    return now;
  }, [filter.data.end, isRange]);

  return (
    <div>
      <div className={'flex w-[220px] items-center justify-between gap-[20px] p-2 pr-10'}>
        <div className={'flex-1 text-sm text-text-caption'}>{field.name}</div>
        <ConditionSelect
          onChange={(e) => {
            const value = Number(e.target.value);

            onChange({
              condition: value,
            });
          }}
          conditions={conditions}
          value={condition}
        />
      </div>
      {showCalendar && (
        <>
          <div className={'flex items-center justify-between gap-[10px] p-2'}>
            <OutlinedInput
              className={isRange ? 'w-[120px]' : 'w-[220px]'}
              size={'small'}
              readOnly={true}
              value={dayjs.unix(timestamp).format('MMM DD, YYYY')}
            />
            {isRange ? (
              <OutlinedInput
                className={'w-[120px]'}
                size={'small'}
                readOnly={true}
                value={dayjs.unix(endTimestamp).format('MMM DD, YYYY')}
              />
            ) : null}
          </div>
          <DateSet
            handleChange={({ date, endDate }) => {
              onChange({
                condition,
                timestamp: date,
                start: date,
                end: endDate,
              });
            }}
            isRange={isRange}
            timestamp={timestamp}
            endTimestamp={endTimestamp}
          />
        </>
      )}
    </div>
  );
}

export default DateFilter;
