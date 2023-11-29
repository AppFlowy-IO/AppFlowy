import React from 'react';
import IncludeTimeSwitch from '$app/components/database/components/field_types/date/IncludeTimeSwitch';
import dayjs from 'dayjs';
import 'react-datepicker/dist/react-datepicker.css';
import TimeInput from '$app/components/database/components/field_types/date/TimeInput';

function TimeSet({
  onChange,
  includeTime,
  time,
  endTime,
  format,
  isRange,
}: {
  onChange: (params: {
    includeTime?: boolean;
    date?: number;
    endDate?: number;
    time?: string;
    endTime?: string;
    isRange?: boolean;
    clearFlag?: boolean;
  }) => void;
  includeTime: boolean;
  time: string;
  endTime: string;
  format: string;
  isRange: boolean;
}) {
  return (
    <div className={'px-4 py-1'}>
      <IncludeTimeSwitch
        onIncludeTimeChange={(val) => {
          void onChange({
            includeTime: val,
            // reset time when includeTime is changed
            time: val ? dayjs().format(format) : undefined,
            endTime: val && isRange ? dayjs().format(format) : undefined,
          });
        }}
        checked={includeTime}
      />
      {includeTime && (
        <div className={'mb-3 flex w-full items-center justify-between gap-2'}>
          <TimeInput
            className={isRange ? 'w-[100px]' : 'w-[225px]'}
            time={time}
            format={format}
            onChange={(time) => onChange({ time })}
          />
          {isRange && (
            <>
              -{' '}
              <TimeInput
                className={'w-[100px]'}
                time={endTime}
                format={format}
                onChange={(endTime) => onChange({ endTime })}
              />
            </>
          )}
        </div>
      )}
    </div>
  );
}

export default TimeSet;
