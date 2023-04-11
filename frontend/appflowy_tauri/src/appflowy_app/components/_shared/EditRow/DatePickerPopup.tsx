import { MouseEventHandler, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import Calendar from 'react-calendar';
import dayjs from 'dayjs';
import { MoreSvg } from '$app/components/_shared/svg/MoreSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { useCell } from '$app/components/_shared/database-hooks/useCell';
import { CalendarData } from '$app/stores/effects/database/cell/controller_builder';
import { DateCellDataPB } from '@/services/backend';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { useAppSelector } from '$app/stores/store';
import { IDateType } from '$app/stores/reducers/database/slice';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { useDateTimeFormat } from '$app/components/_shared/EditRow/DateTimeFormat.hooks';

export const DatePickerPopup = ({
  left,
  top,
  cellIdentifier,
  cellCache,
  fieldController,
  onOutsideClick,
  onDateFormatClick,
  onTimeFormatClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  cellCache: CellCache;
  fieldController: FieldController;
  onOutsideClick: () => void;
  onDateFormatClick: (_left: number, _top: number) => void;
  onTimeFormatClick: (_left: number, _top: number) => void;
}) => {
  const { data, cellController } = useCell(cellIdentifier, cellCache, fieldController);
  const { t } = useTranslation('');
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [dateType, setDateType] = useState<IDateType | undefined>();
  const databaseStore = useAppSelector((state) => state.database);
  const { includeTime } = useDateTimeFormat(cellIdentifier, fieldController);

  useEffect(() => {
    const date_pb = data as DateCellDataPB | undefined;
    if (!date_pb || !date_pb?.date.length) return;

    // should be changed after we can modify date format
    setSelectedDate(dayjs(date_pb.date, 'MMM DD, YYYY').toDate());
  }, [data]);

  useEffect(() => {
    setDateType(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as IDateType);
  }, [databaseStore]);

  const onChange = async (v: Date | null | (Date | null)[]) => {
    if (v instanceof Date) {
      setSelectedDate(v);
      const date = new CalendarData(dayjs(v).add(dayjs().utcOffset(), 'minutes').toDate(), false);
      await cellController?.saveCellData(date);
    }
  };

  const _onDateFormatClick: MouseEventHandler = (e) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const { right: _left, top: _top } = target.getBoundingClientRect();
    onDateFormatClick(_left, _top);
  };

  const _onTimeFormatClick: MouseEventHandler = (e) => {
    e.stopPropagation();
    let target = e.target as HTMLElement;

    while (!(target instanceof HTMLButtonElement)) {
      if (target.parentElement === null) return;
      target = target.parentElement;
    }

    const { right: _left, top: _top } = target.getBoundingClientRect();
    onTimeFormatClick(_left, _top);
  };

  const toggleIncludeTime = async () => {
    if (dateType?.includeTime) {
      await includeTime(false);
    } else {
      await includeTime(true);
    }
  };

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <div className={'px-2 pb-2'}>
        <Calendar onChange={(d) => onChange(d)} value={selectedDate} />
      </div>
      <hr className={'-mx-2 my-2 border-shade-6'} />
      <button
        onClick={_onDateFormatClick}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-4 py-2 hover:bg-main-secondary'
        }
      >
        <span>{t('grid.field.dateFormat')}</span>
        <i className={'h-5 w-5'}>
          <MoreSvg></MoreSvg>
        </i>
      </button>
      <hr className={'-mx-2 my-2 border-shade-6'} />
      <button
        onClick={() => toggleIncludeTime()}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-4 py-2 hover:bg-main-secondary'
        }
      >
        <div className={'flex items-center gap-2'}>
          {/*<i className={'h-4 w-4'}>
            <ClockSvg></ClockSvg>
          </i>*/}
          <span>{t('grid.field.includeTime')}</span>
        </div>
        <i className={'h-5 w-5'}>
          {dateType?.includeTime ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}
        </i>
      </button>

      <button
        onClick={_onTimeFormatClick}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-4 py-2 hover:bg-main-secondary'
        }
      >
        <span>{t('grid.field.timeFormat')}</span>
        <i className={'h-5 w-5'}>
          <MoreSvg></MoreSvg>
        </i>
      </button>
    </PopupWindow>
  );
};
