import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { useTranslation } from 'react-i18next';
import { DateFormatPB } from '@/services/backend';
import { useDateTimeFormat } from '$app/components/_shared/EditRow/Date/DateTimeFormat.hooks';
import { useAppSelector } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { IDateType } from '$app_reducers/database/slice';

export const DateFormatPopup = ({
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
  const { changeDateFormat } = useDateTimeFormat(cellIdentifier, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const [dateType, setDateType] = useState<IDateType | undefined>();

  useEffect(() => {
    setDateType(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as IDateType);
  }, [databaseStore]);

  const changeFormat = async (format: DateFormatPB) => {
    await changeDateFormat(format);
    onOutsideClick();
  };

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <PopupItem
        changeFormat={changeFormat}
        format={DateFormatPB.Friendly}
        checked={dateType?.dateFormat === DateFormatPB.Friendly}
        text={t('grid.field.dateFormatFriendly')}
      />
      <PopupItem
        changeFormat={changeFormat}
        format={DateFormatPB.ISO}
        checked={dateType?.dateFormat === DateFormatPB.ISO}
        text={t('grid.field.dateFormatISO')}
      />
      <PopupItem
        changeFormat={changeFormat}
        format={DateFormatPB.Local}
        checked={dateType?.dateFormat === DateFormatPB.Local}
        text={t('grid.field.dateFormatLocal')}
      />
      <PopupItem
        changeFormat={changeFormat}
        format={DateFormatPB.US}
        checked={dateType?.dateFormat === DateFormatPB.US}
        text={t('grid.field.dateFormatUS')}
      />
    </PopupWindow>
  );
};

function PopupItem({
  format,
  text,
  changeFormat,
  checked,
}: {
  format: DateFormatPB;
  text: string;
  changeFormat: (_: DateFormatPB) => Promise<void>;
  checked: boolean;
}) {
  return (
    <button
      onClick={() => changeFormat(format)}
      className={
        'flex w-full cursor-pointer items-center justify-between rounded-lg px-2 py-1.5 hover:bg-main-secondary'
      }
    >
      {text}

      {checked && (
        <div className={'ml-8 h-5 w-5 p-1'}>
          <CheckmarkSvg></CheckmarkSvg>
        </div>
      )}
    </button>
  );
}
