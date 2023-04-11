import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { CellCache } from '$app/stores/effects/database/cell/cell_cache';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { useTranslation } from 'react-i18next';
import { DateFormat } from '@/services/backend';
import { useDateTimeFormat } from '$app/components/_shared/EditRow/DateTimeFormat.hooks';
import { useAppSelector } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { IDateType } from '$app/stores/reducers/database/slice';

export const DateFormatPopup = ({
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
  const { t } = useTranslation('');
  const { changeDateFormat } = useDateTimeFormat(cellIdentifier, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const [dateType, setDateType] = useState<IDateType | undefined>();

  useEffect(() => {
    setDateType(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as IDateType);
  }, [databaseStore]);

  const changeFormat = async (format: DateFormat) => {
    await changeDateFormat(format);
    onOutsideClick();
  };

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <button
        onClick={() => changeFormat(DateFormat.Friendly)}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
        }
      >
        {t('grid.field.dateFormatFriendly')}

        {dateType?.dateFormat === DateFormat.Friendly && (
          <div className={'ml-8 h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </div>
        )}
      </button>
      <button
        onClick={() => changeFormat(DateFormat.ISO)}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
        }
      >
        {t('grid.field.dateFormatISO')}

        {dateType?.dateFormat === DateFormat.ISO && (
          <div className={'ml-8 h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </div>
        )}
      </button>
      <button
        onClick={() => changeFormat(DateFormat.Local)}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
        }
      >
        {t('grid.field.dateFormatLocal')}

        {dateType?.dateFormat === DateFormat.Local && (
          <div className={'ml-8 h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </div>
        )}
      </button>
      <button
        onClick={() => changeFormat(DateFormat.US)}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
        }
      >
        {t('grid.field.dateFormatUS')}
        {dateType?.dateFormat === DateFormat.US && (
          <div className={'ml-8 h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </div>
        )}
      </button>
    </PopupWindow>
  );
};
