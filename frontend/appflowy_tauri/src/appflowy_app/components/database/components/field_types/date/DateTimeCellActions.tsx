import React, { useCallback, useMemo } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { DateTimeCell, DateTimeField, DateTimeTypeOption } from '$app/components/database/application';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { updateDateCell } from '$app/components/database/application/cell/cell_service';
import { Divider, MenuItem, MenuList } from '@mui/material';
import dayjs from 'dayjs';
import RangeSwitch from '$app/components/database/components/field_types/date/RangeSwitch';
import CustomCalendar from '$app/components/database/components/field_types/date/CustomCalendar';
import IncludeTimeSwitch from '$app/components/database/components/field_types/date/IncludeTimeSwitch';
import DateTimeFormatSelect from '$app/components/database/components/field_types/date/DateTimeFormatSelect';
import DateTimeSet from '$app/components/database/components/field_types/date/DateTimeSet';
import { useTypeOption } from '$app/components/database';
import { getDateFormat, getTimeFormat } from '$app/components/database/components/field_types/date/utils';

function DateTimeCellActions({
  cell,
  field,
  ...props
}: PopoverProps & {
  field: DateTimeField;
  cell: DateTimeCell;
}) {
  const typeOption = useTypeOption<DateTimeTypeOption>(field.id);

  const timeFormat = useMemo(() => {
    return getTimeFormat(typeOption.timeFormat);
  }, [typeOption.timeFormat]);

  const dateFormat = useMemo(() => {
    return getDateFormat(typeOption.dateFormat);
  }, [typeOption.dateFormat]);

  const { includeTime } = cell.data;

  const timestamp = useMemo(() => cell.data.timestamp || dayjs().unix(), [cell.data.timestamp]);
  const endTimestamp = useMemo(() => cell.data.endTimestamp || dayjs().unix(), [cell.data.endTimestamp]);
  const time = useMemo(() => cell.data.time || dayjs().format(timeFormat), [cell.data.time, timeFormat]);
  const endTime = useMemo(() => cell.data.endTime || dayjs().format(timeFormat), [cell.data.endTime, timeFormat]);

  const viewId = useViewId();
  const { t } = useTranslation();

  const handleChange = useCallback(
    async (params: {
      includeTime?: boolean;
      date?: number;
      endDate?: number;
      time?: string;
      endTime?: string;
      isRange?: boolean;
      clearFlag?: boolean;
    }) => {
      try {
        const isRange = params.isRange ?? cell.data.isRange;

        await updateDateCell(viewId, cell.rowId, cell.fieldId, {
          date: params.date ?? timestamp,
          endDate: isRange ? params.endDate ?? endTimestamp : undefined,
          time: params.time ?? time,
          endTime: isRange ? params.endTime ?? endTime : undefined,
          includeTime: params.includeTime ?? includeTime,
          isRange,
          clearFlag: params.clearFlag,
        });
      } catch (e) {
        // toast.error(e.message);
      }
    },
    [cell, endTime, endTimestamp, includeTime, time, timestamp, viewId]
  );

  const isRange = cell.data.isRange || false;

  return (
    <Popover
      keepMounted={false}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'left',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
      {...props}
      PaperProps={{
        className: 'pt-4 transform transition-all',
      }}
    >
      <DateTimeSet
        date={timestamp}
        endTime={endTime}
        endDate={endTimestamp}
        dateFormat={dateFormat}
        time={time}
        timeFormat={timeFormat}
        onChange={handleChange}
        isRange={isRange}
        includeTime={includeTime}
      />

      <CustomCalendar isRange={isRange} timestamp={timestamp} endTimestamp={endTimestamp} handleChange={handleChange} />

      <Divider className={'my-0'} />
      <div className={'flex flex-col gap-1 px-4 py-2'}>
        <RangeSwitch
          onIsRangeChange={(val) => {
            void handleChange({
              isRange: val,
              // reset endTime when isRange is changed
              endTime: time,
              endDate: timestamp,
            });
          }}
          checked={isRange}
        />
        <IncludeTimeSwitch
          onIncludeTimeChange={(val) => {
            void handleChange({
              includeTime: val,
              // reset time when includeTime is changed
              time: val ? dayjs().format(timeFormat) : undefined,
              endTime: val && isRange ? dayjs().format(timeFormat) : undefined,
            });
          }}
          checked={includeTime}
        />
      </div>

      <Divider className={'my-0'} />

      <MenuList>
        <DateTimeFormatSelect field={field} />
        <MenuItem
          className={'text-xs font-medium'}
          onClick={async () => {
            await handleChange({
              clearFlag: true,
            });

            props.onClose?.({}, 'backdropClick');
          }}
        >
          {t('grid.field.clearDate')}
        </MenuItem>
      </MenuList>
    </Popover>
  );
}

export default DateTimeCellActions;
