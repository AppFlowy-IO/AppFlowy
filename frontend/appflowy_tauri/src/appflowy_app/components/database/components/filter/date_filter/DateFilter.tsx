import React, { useMemo } from 'react';
import {
  DateFilter as DateFilterType,
  DateFilterData,
  DateTimeField,
  DateTimeTypeOption,
} from '$app/components/database/application';
import { DateFilterConditionPB, DateFormatPB, TimeFormatPB } from '@/services/backend';
import CustomCalendar from '$app/components/database/components/field_types/date/CustomCalendar';
import DateTimeSet from '$app/components/database/components/field_types/date/DateTimeSet';
import { useTypeOption } from '$app/components/database';

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

  const timeFormat = useMemo(() => {
    switch (typeOption.timeFormat) {
      case TimeFormatPB.TwelveHour:
        return 'h:mm A';
      case TimeFormatPB.TwentyFourHour:
        return 'HH:mm';
      default:
        return 'HH:mm';
    }
  }, [typeOption.timeFormat]);

  const dateFormat = useMemo(() => {
    switch (typeOption.dateFormat) {
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
                  start: date,
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
