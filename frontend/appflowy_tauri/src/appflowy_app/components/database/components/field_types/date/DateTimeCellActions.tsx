import React, { useCallback, useMemo } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { DateTimeCell, DateTimeField } from '$app/components/database/application';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { updateDateCell } from '$app/components/database/application/cell/cell_service';

import { Divider, MenuItem, MenuList } from '@mui/material';
import { TimeFormatPB } from '@/services/backend';
import dayjs from 'dayjs';
import RangeSwitch from '$app/components/database/components/field_types/date/RangeSwitch';
import DateTimeFormat from '$app/components/database/components/field_types/date/DateTimeFormat';
import TimeSet from '$app/components/database/components/field_types/date/TimeSet';
import DateSet from '$app/components/database/components/field_types/date/DateSet';

function DateTimeCellActions({
  cell,
  field,
  ...props
}: PopoverProps & {
  field: DateTimeField;
  cell: DateTimeCell;
}) {
  const { timeFormat = TimeFormatPB.TwentyFourHour } = field.typeOption;
  const format = useMemo(() => {
    switch (timeFormat) {
      case TimeFormatPB.TwelveHour:
        return 'h:mm A';
      case TimeFormatPB.TwentyFourHour:
        return 'HH:mm';
      default:
        return 'HH:mm';
    }
  }, [timeFormat]);

  const { includeTime } = cell.data;

  const timestamp = useMemo(() => cell.data.timestamp || dayjs().unix(), [cell.data.timestamp]);
  const endTimestamp = useMemo(() => cell.data.endTimestamp || dayjs().unix(), [cell.data.endTimestamp]);
  const time = useMemo(() => cell.data.time || dayjs().format(format), [cell.data.time, format]);
  const endTime = useMemo(() => cell.data.endTime || dayjs().format(format), [cell.data.endTime, format]);

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
    >
      <DateSet isRange={isRange} timestamp={timestamp} endTimestamp={endTimestamp} handleChange={handleChange} />
      <div className={'px-4 py-1'}>
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
      </div>
      <Divider />
      <TimeSet
        time={time}
        endTime={endTime}
        format={format}
        isRange={isRange || false}
        includeTime={includeTime || false}
        onChange={handleChange}
      />

      <Divider className={'my-0'} />
      <MenuList className={'my-1 ml-[-3px]'}>
        <DateTimeFormat field={field} />
      </MenuList>

      <Divider className={'my-0'} />
      <MenuList>
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
