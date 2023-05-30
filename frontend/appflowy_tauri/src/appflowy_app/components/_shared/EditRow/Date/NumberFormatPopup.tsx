import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { useNumberFormat } from '$app/components/_shared/EditRow/Date/NumberFormat.hooks';
import { NumberFormatPB } from '@/services/backend';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { useAppSelector } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { INumberType } from '$app_reducers/database/slice';

const list = [
  { format: NumberFormatPB.Num, title: 'Num' },
  { format: NumberFormatPB.USD, title: 'USD' },
  { format: NumberFormatPB.CanadianDollar, title: 'CanadianDollar' },
  { format: NumberFormatPB.EUR, title: 'EUR' },
  { format: NumberFormatPB.Pound, title: 'Pound' },
  { format: NumberFormatPB.Yen, title: 'Yen' },
  { format: NumberFormatPB.Ruble, title: 'Ruble' },
  { format: NumberFormatPB.Rupee, title: 'Rupee' },
  { format: NumberFormatPB.Won, title: 'Won' },
  { format: NumberFormatPB.Yuan, title: 'Yuan' },
  { format: NumberFormatPB.Real, title: 'Real' },
  { format: NumberFormatPB.Lira, title: 'Lira' },
  { format: NumberFormatPB.Rupiah, title: 'Rupiah' },
  { format: NumberFormatPB.Franc, title: 'Franc' },
  { format: NumberFormatPB.HongKongDollar, title: 'HongKongDollar' },
  { format: NumberFormatPB.NewZealandDollar, title: 'NewZealandDollar' },
  { format: NumberFormatPB.Krona, title: 'Krona' },
  { format: NumberFormatPB.NorwegianKrone, title: 'NorwegianKrone' },
  { format: NumberFormatPB.MexicanPeso, title: 'MexicanPeso' },
  { format: NumberFormatPB.Rand, title: 'Rand' },
  { format: NumberFormatPB.NewTaiwanDollar, title: 'NewTaiwanDollar' },
  { format: NumberFormatPB.DanishKrone, title: 'DanishKrone' },
  { format: NumberFormatPB.Baht, title: 'Baht' },
  { format: NumberFormatPB.Forint, title: 'Forint' },
  { format: NumberFormatPB.Koruna, title: 'Koruna' },
  { format: NumberFormatPB.Shekel, title: 'Shekel' },
  { format: NumberFormatPB.ChileanPeso, title: 'ChileanPeso' },
  { format: NumberFormatPB.PhilippinePeso, title: 'PhilippinePeso' },
  { format: NumberFormatPB.Dirham, title: 'Dirham' },
  { format: NumberFormatPB.ColombianPeso, title: 'ColombianPeso' },
  { format: NumberFormatPB.Riyal, title: 'Riyal' },
  { format: NumberFormatPB.Ringgit, title: 'Ringgit' },
  { format: NumberFormatPB.Leu, title: 'Leu' },
  { format: NumberFormatPB.ArgentinePeso, title: 'ArgentinePeso' },
  { format: NumberFormatPB.UruguayanPeso, title: 'UruguayanPeso' },
  { format: NumberFormatPB.Percent, title: 'Percent' },
];

export const NumberFormatPopup = ({
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
  const { changeNumberFormat } = useNumberFormat(cellIdentifier, fieldController);
  const databaseStore = useAppSelector((state) => state.database);
  const [numberType, setNumberType] = useState<INumberType | undefined>();

  useEffect(() => {
    setNumberType(databaseStore.fields[cellIdentifier.fieldId]?.fieldOptions as INumberType);
  }, [databaseStore]);

  const changeNumberFormatClick = async (format: NumberFormatPB) => {
    await changeNumberFormat(format);
    onOutsideClick();
  };

  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <div className={'h-[400px] overflow-auto'}>
        {list.map((item, index) => (
          <FormatButton
            key={index}
            title={item.title}
            checked={numberType?.numberFormat === item.format}
            onClick={() => changeNumberFormatClick(item.format)}
          ></FormatButton>
        ))}
      </div>
    </PopupWindow>
  );
};

const FormatButton = ({ title, checked, onClick }: { title: string; checked: boolean; onClick: () => void }) => {
  return (
    <button
      onClick={() => onClick()}
      className={
        'flex w-full cursor-pointer items-center justify-between rounded-lg py-1.5 px-2 hover:bg-main-secondary'
      }
    >
      <span className={'block pr-8'}>{title}</span>
      {checked && (
        <div className={'h-5 w-5 p-1'}>
          <CheckmarkSvg></CheckmarkSvg>
        </div>
      )}
    </button>
  );
};
