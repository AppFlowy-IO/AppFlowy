import { useEffect, useState } from 'react';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import Calendar from 'react-calendar';
import dayjs from 'dayjs';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CalendarData } from '$app/stores/effects/database/cell/controller_builder';
import { DateCellDataPB } from '@/services/backend';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { DateTypeOptions } from '$app/components/_shared/EditRow/Date/DateTypeOptions';

export const DatePickerPopup = ({
  left,
  top,
  cellIdentifier,
  cellCache,
  fieldController,
  onOutsideClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onOutsideClick: () => void;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());

  useEffect(() => {
    const date_pb = data as DateCellDataPB | undefined;
    if (!date_pb || !date_pb?.date.length) return;

    setSelectedDate(dayjs(date_pb.date).toDate());
  }, [data]);

  const onChange = async (v: Date | null | (Date | null)[]) => {
    if (v instanceof Date) {
      setSelectedDate(v);
      const date = new CalendarData(dayjs(v).add(dayjs().utcOffset(), 'minutes').toDate(), false);
      await cellController?.saveCellData(date);
    }
  };

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <div className={'px-2 pb-2'}>
        <Calendar onChange={(d) => onChange(d)} value={selectedDate} />
      </div>
      <DateTypeOptions cellIdentifier={cellIdentifier} fieldController={fieldController}></DateTypeOptions>
    </PopupWindow>
  );
};
