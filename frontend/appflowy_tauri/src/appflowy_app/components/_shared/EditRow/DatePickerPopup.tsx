import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import useOutsideClick from '$app/components/_shared/useOutsideClick';
import Calendar from 'react-calendar';
import dayjs from 'dayjs';
import { ClockSvg } from '$app/components/_shared/svg/ClockSvg';
import { MoreSvg } from '$app/components/_shared/svg/MoreSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { useCell } from '$app/components/_shared/database-hooks/useCell';

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
  const ref = useRef<HTMLDivElement>(null);
  const [adjustedTop, setAdjustedTop] = useState(-100);
  // const [value, setValue] = useState();
  const { t } = useTranslation('');
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());

  useEffect(() => {
    if (!ref.current) return;
    const { height } = ref.current.getBoundingClientRect();
    if (top + height + 40 > window.innerHeight) {
      setAdjustedTop(top - height - 40);
    } else {
      setAdjustedTop(top);
    }
  }, [ref, window, top, left]);

  useOutsideClick(ref, async () => {
    onOutsideClick();
  });

  useEffect(() => {
    // console.log((data as DateCellDataPB).date);
    // setSelectedDate(new Date((data as DateCellDataPB).date));
  }, [data]);

  const onChange = (v: Date | null | (Date | null)[]) => {
    if (v instanceof Date) {
      console.log(dayjs(v).format('YYYY-MM-DD'));
      setSelectedDate(v);
      // void cellController?.saveCellData(new DateCellDataPB({ date: dayjs(v).format('YYYY-MM-DD') }));
    }
  };

  return (
    <div
      ref={ref}
      className={`fixed z-10 rounded-lg bg-white px-2 py-2 text-xs shadow-md transition-opacity duration-300 ${
        adjustedTop === -100 ? 'opacity-0' : 'opacity-100'
      }`}
      style={{ top: `${adjustedTop + 40}px`, left: `${left}px` }}
    >
      <div className={'px-2'}>
        <Calendar onChange={(d) => onChange(d)} value={selectedDate} />
      </div>
      <hr className={'-mx-2 my-4 border-shade-6'} />
      <div className={'flex items-center justify-between px-4'}>
        <div className={'flex items-center gap-2'}>
          <i className={'h-4 w-4'}>
            <ClockSvg></ClockSvg>
          </i>
          <span>{t('grid.field.includeTime')}</span>
        </div>
        <i className={'h-5 w-5'}>
          <EditorUncheckSvg></EditorUncheckSvg>
        </i>
      </div>
      <hr className={'-mx-2 my-4 border-shade-6'} />
      <div className={'flex items-center justify-between px-4 pb-2'}>
        <span>
          {t('grid.field.dateFormat')} & {t('grid.field.timeFormat')}
        </span>
        <i className={'h-5 w-5'}>
          <MoreSvg></MoreSvg>
        </i>
      </div>
    </div>
  );
};
