import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { useTranslation } from 'react-i18next';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { TimeFormatPB } from '@/services/backend';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { useDateTimeFormat } from '$app/components/_shared/EditRow/Date/DateTimeFormat.hooks';
import { useAppSelector } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { IDateType } from '$app_reducers/database/slice';

export const TimeFormatPopup = ({
  left,
  top,
  cellIdentifier,
  fieldController,
  onOutsideClick,
}: {
  left: number;
  top: number;
  cellIdentifier: CellIdentifier;
  fieldController: FieldController;
  onOutsideClick: () => void;
}) => {
  const { t } = useTranslation();
  const databaseStore = useAppSelector((state) => state.database);
  const [dateType, setDateType] = useState<IDateType | undefined>();

  useEffect(() => {
    setDateType(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as IDateType);
  }, [databaseStore]);

  const { changeTimeFormat } = useDateTimeFormat(cellIdentifier, fieldController);

  const changeFormat = async (format: TimeFormatPB) => {
    await changeTimeFormat(format);
    onOutsideClick();
  };

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <button
        onClick={() => changeFormat(TimeFormatPB.TwelveHour)}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
        }
      >
        {t('grid.field.timeFormatTwelveHour')}

        {dateType?.timeFormat === TimeFormatPB.TwelveHour && (
          <div className={'ml-8 h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </div>
        )}
      </button>
      <button
        onClick={() => changeFormat(TimeFormatPB.TwentyFourHour)}
        className={
          'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
        }
      >
        {t('grid.field.timeFormatTwentyFourHour')}

        {dateType?.timeFormat === TimeFormatPB.TwentyFourHour && (
          <div className={'ml-8 h-5 w-5 p-1'}>
            <CheckmarkSvg></CheckmarkSvg>
          </div>
        )}
      </button>
    </PopupWindow>
  );
};
