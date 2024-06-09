import React, { useMemo } from 'react';
import {
  DateFilter as DateFilterType,
  DateFilterData,
  DateTimeField,
  DateTimeTypeOption,
} from '$app/application/database';
import { DateFilterConditionPB } from '@/services/backend';
import CustomCalendar from '$app/components/database/components/field_types/date/CustomCalendar';
import DateTimeSet from '$app/components/database/components/field_types/date/DateTimeSet';
import { useTypeOption } from '$app/components/database';
import { getDateFormat, getTimeFormat } from '$app/components/database/components/field_types/date/utils';

interface Props {
  filter: DateFilterType;
  field: DateTimeField;
  onChange: (filterData: DateFilterData) => void;
}

function DateFilter({ filter, field, onChange }: Props) {
  const typeOption = useTypeOption<DateTimeTypeOption>(field.id);

  const showCalendar =
    filter.data.condition !== DateFilterConditionPB.DateIsEmpty &&
    filter.data.condition !== DateFilterConditionPB.DateIsNotEmpty;

  const condition = filter.data.condition;
  const isRange = condition === DateFilterConditionPB.DateWithIn;
  const timestamp = useMemo(() => {
    if (isRange) {
      return filter.data.start;
    }

    return filter.data.timestamp;
  }, [filter.data.start, filter.data.timestamp, isRange]);

  const endTimestamp = useMemo(() => {
    if (isRange) {
      return filter.data.end;
    }

    return;
  }, [filter.data.end, isRange]);

  const timeFormat = useMemo(() => {
    return getTimeFormat(typeOption.timeFormat);
  }, [typeOption.timeFormat]);

  const dateFormat = useMemo(() => {
    return getDateFormat(typeOption.dateFormat);
  }, [typeOption.dateFormat]);

  return (
    <div>
      {showCalendar && (
        <>
          <div className={'flex flex-col justify-center'}>
            <DateTimeSet
              onChange={({ date, endDate }) => {
                onChange({
                  condition,
                  timestamp: date,
                  start: endDate ? date : undefined,
                  end: endDate,
                });
              }}
              date={timestamp}
              endDate={endTimestamp}
              timeFormat={timeFormat}
              dateFormat={dateFormat}
              includeTime={false}
              isRange={isRange}
            />
          </div>
          <CustomCalendar
            handleChange={({ date, endDate }) => {
              onChange({
                condition,
                timestamp: date,
                start: endDate ? date : undefined,
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
