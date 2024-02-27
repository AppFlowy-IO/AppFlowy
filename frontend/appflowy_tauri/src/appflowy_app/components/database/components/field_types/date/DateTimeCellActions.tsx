import React, { useCallback, useMemo } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { DateTimeCell, DateTimeField, DateTimeTypeOption } from '$app/application/database';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { updateDateCell } from '$app/application/database/cell/cell_service';
import { Divider, MenuItem, MenuList } from '@mui/material';
import dayjs from 'dayjs';
import RangeSwitch from '$app/components/database/components/field_types/date/RangeSwitch';
import CustomCalendar from '$app/components/database/components/field_types/date/CustomCalendar';
import IncludeTimeSwitch from '$app/components/database/components/field_types/date/IncludeTimeSwitch';
import DateTimeFormatSelect from '$app/components/database/components/field_types/date/DateTimeFormatSelect';
import DateTimeSet from '$app/components/database/components/field_types/date/DateTimeSet';
import { useTypeOption } from '$app/components/database';
import { getDateFormat, getTimeFormat } from '$app/components/database/components/field_types/date/utils';
import { notify } from '$app/components/_shared/notify';

function DateTimeCellActions({
  cell,
  field,
  maxWidth,
  maxHeight,
  ...props
}: PopoverProps & {
  field: DateTimeField;
  cell: DateTimeCell;
  maxWidth?: number;
  maxHeight?: number;
}) {
  const typeOption = useTypeOption<DateTimeTypeOption>(field.id);

  const timeFormat = useMemo(() => {
    return getTimeFormat(typeOption.timeFormat);
  }, [typeOption.timeFormat]);

  const dateFormat = useMemo(() => {
    return getDateFormat(typeOption.dateFormat);
  }, [typeOption.dateFormat]);

  const { includeTime } = cell.data;

  const timestamp = useMemo(() => cell.data.timestamp || undefined, [cell.data.timestamp]);
  const endTimestamp = useMemo(() => cell.data.endTimestamp || undefined, [cell.data.endTimestamp]);
  const time = useMemo(() => cell.data.time || undefined, [cell.data.time]);
  const endTime = useMemo(() => cell.data.endTime || undefined, [cell.data.endTime]);

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

        const data = {
          date: params.date ?? timestamp,
          endDate: isRange ? params.endDate ?? endTimestamp : undefined,
          time: params.time ?? time,
          endTime: isRange ? params.endTime ?? endTime : undefined,
          includeTime: params.includeTime ?? includeTime,
          isRange,
          clearFlag: params.clearFlag,
        };

        // if isRange and date is greater than endDate, swap date and endDate
        if (
          data.isRange &&
          data.date &&
          data.endDate &&
          dayjs(dayjs.unix(data.date).format('YYYY/MM/DD ') + data.time).unix() >
            dayjs(dayjs.unix(data.endDate).format('YYYY/MM/DD ') + data.endTime).unix()
        ) {
          if (params.date || params.time) {
            data.endDate = data.date;
            data.endTime = data.time;
          }

          if (params.endDate || params.endTime) {
            data.date = data.endDate;
            data.time = data.endTime;
          }
        }

        await updateDateCell(viewId, cell.rowId, cell.fieldId, data);
      } catch (e) {
        notify.error(String(e));
      }
    },
    [cell, endTime, endTimestamp, includeTime, time, timestamp, viewId]
  );

  const isRange = cell.data.isRange || false;

  return (
    <Popover
      keepMounted={false}
      disableRestoreFocus={true}
      {...props}
      PaperProps={{
        ...props.PaperProps,
        className: 'pt-4 transform transition-all',
      }}
      onKeyDown={(e) => {
        if (e.key === 'Escape') {
          e.preventDefault();
          e.stopPropagation();
          props.onClose?.({}, 'escapeKeyDown');
        }
      }}
    >
      <div
        style={{
          maxWidth: maxWidth,
          maxHeight: maxHeight,
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

        <CustomCalendar
          isRange={isRange}
          timestamp={timestamp}
          endTimestamp={endTimestamp}
          handleChange={handleChange}
        />

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
            disabled={!timestamp}
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
                isRange: false,
                includeTime: false,
              });
              await handleChange({
                clearFlag: true,
              });

              props.onClose?.({}, 'backdropClick');
            }}
          >
            {t('grid.field.clearDate')}
          </MenuItem>
        </MenuList>
      </div>
    </Popover>
  );
}

export default DateTimeCellActions;
