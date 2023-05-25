import { DateFormatPopup } from '$app/components/_shared/EditRow/Date/DateFormatPopup';
import { TimeFormatPopup } from '$app/components/_shared/EditRow/Date/TimeFormatPopup';
import { MoreSvg } from '$app/components/_shared/svg/MoreSvg';
import { EditorCheckSvg } from '$app/components/_shared/svg/EditorCheckSvg';
import { EditorUncheckSvg } from '$app/components/_shared/svg/EditorUncheckSvg';
import { MouseEventHandler, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { IDateType } from '$app_reducers/database/slice';
import { useAppSelector } from '$app/stores/store';
import { useDateTimeFormat } from '$app/components/_shared/EditRow/Date/DateTimeFormat.hooks';
import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';

export const DateTypeOptions = ({
  cellIdentifier,
  fieldController,
}: {
  cellIdentifier: CellIdentifier;
  fieldController: FieldController;
}) => {
  const { t } = useTranslation();

  const [showDateFormatPopup, setShowDateFormatPopup] = useState(false);
  const [dateFormatTop, setDateFormatTop] = useState(0);
  const [dateFormatLeft, setDateFormatLeft] = useState(0);

  const [showTimeFormatPopup, setShowTimeFormatPopup] = useState(false);
  const [timeFormatTop, setTimeFormatTop] = useState(0);
  const [timeFormatLeft, setTimeFormatLeft] = useState(0);

  const [dateType, setDateType] = useState<IDateType | undefined>();

  const databaseStore = useAppSelector((state) => state.database);
  const { includeTime } = useDateTimeFormat(cellIdentifier, fieldController);

  useEffect(() => {
    setDateType(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as IDateType);
  }, [databaseStore]);

  const onDateFormatClick = (_left: number, _top: number) => {
    setShowDateFormatPopup(true);
    setDateFormatLeft(_left + 10);
    setDateFormatTop(_top);
  };

  const onTimeFormatClick = (_left: number, _top: number) => {
    setShowTimeFormatPopup(true);
    setTimeFormatLeft(_left + 10);
    setTimeFormatTop(_top);
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
    // if (dateType?.includeTime) {
    //   await includeTime(false);
    // } else {
    //   await includeTime(true);
    // }
  };

  return (
    <div className={'flex flex-col'}>
      <hr className={'-mx-2 my-2 border-shade-6'} />
      <button
        onClick={_onDateFormatClick}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-2 hover:bg-main-secondary'
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
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-2 hover:bg-main-secondary'
        }
      >
        <div className={'flex items-center gap-2'}>
          <span>{t('grid.field.includeTime')}</span>
        </div>
        {/*<i className={'h-5 w-5'}>*/}
        {/*  {dateType?.includeTime ? <EditorCheckSvg></EditorCheckSvg> : <EditorUncheckSvg></EditorUncheckSvg>}*/}
        {/*</i>*/}
      </button>

      <button
        onClick={_onTimeFormatClick}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-2 hover:bg-main-secondary'
        }
      >
        <span>{t('grid.field.timeFormat')}</span>
        <i className={'h-5 w-5'}>
          <MoreSvg></MoreSvg>
        </i>
      </button>
      {showDateFormatPopup && (
        <DateFormatPopup
          top={dateFormatTop}
          left={dateFormatLeft}
          cellIdentifier={cellIdentifier}
          fieldController={fieldController}
          onOutsideClick={() => setShowDateFormatPopup(false)}
        ></DateFormatPopup>
      )}
      {showTimeFormatPopup && (
        <TimeFormatPopup
          top={timeFormatTop}
          left={timeFormatLeft}
          cellIdentifier={cellIdentifier}
          fieldController={fieldController}
          onOutsideClick={() => setShowTimeFormatPopup(false)}
        ></TimeFormatPopup>
      )}
    </div>
  );
};
