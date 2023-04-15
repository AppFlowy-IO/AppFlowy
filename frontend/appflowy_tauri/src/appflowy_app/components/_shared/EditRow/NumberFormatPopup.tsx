import { CellIdentifier } from '$app/stores/effects/database/cell/cell_bd_svc';
import { FieldController } from '$app/stores/effects/database/field/field_controller';
import { PopupWindow } from '$app/components/_shared/PopupWindow';
import { useNumberFormat } from '$app/components/_shared/EditRow/NumberFormat.hooks';
import { NumberFormat } from '@/services/backend';
import { CheckmarkSvg } from '$app/components/_shared/svg/CheckmarkSvg';
import { useAppSelector } from '$app/stores/store';
import { useEffect, useState } from 'react';
import { INumberType } from '$app/stores/reducers/database/slice';

const list = [
  { format: NumberFormat.Num, title: 'Num' },
  { format: NumberFormat.USD, title: 'USD' },
  { format: NumberFormat.CanadianDollar, title: 'CanadianDollar' },
  { format: NumberFormat.EUR, title: 'EUR' },
  { format: NumberFormat.Pound, title: 'Pound' },
  { format: NumberFormat.Yen, title: 'Yen' },
  { format: NumberFormat.Ruble, title: 'Ruble' },
  { format: NumberFormat.Rupee, title: 'Rupee' },
  { format: NumberFormat.Won, title: 'Won' },
  { format: NumberFormat.Yuan, title: 'Yuan' },
  { format: NumberFormat.Real, title: 'Real' },
  { format: NumberFormat.Lira, title: 'Lira' },
  { format: NumberFormat.Rupiah, title: 'Rupiah' },
  { format: NumberFormat.Franc, title: 'Franc' },
  { format: NumberFormat.HongKongDollar, title: 'HongKongDollar' },
  { format: NumberFormat.NewZealandDollar, title: 'NewZealandDollar' },
  { format: NumberFormat.Krona, title: 'Krona' },
  { format: NumberFormat.NorwegianKrone, title: 'NorwegianKrone' },
  { format: NumberFormat.MexicanPeso, title: 'MexicanPeso' },
  { format: NumberFormat.Rand, title: 'Rand' },
  { format: NumberFormat.NewTaiwanDollar, title: 'NewTaiwanDollar' },
  { format: NumberFormat.DanishKrone, title: 'DanishKrone' },
  { format: NumberFormat.Baht, title: 'Baht' },
  { format: NumberFormat.Forint, title: 'Forint' },
  { format: NumberFormat.Koruna, title: 'Koruna' },
  { format: NumberFormat.Shekel, title: 'Shekel' },
  { format: NumberFormat.ChileanPeso, title: 'ChileanPeso' },
  { format: NumberFormat.PhilippinePeso, title: 'PhilippinePeso' },
  { format: NumberFormat.Dirham, title: 'Dirham' },
  { format: NumberFormat.ColombianPeso, title: 'ColombianPeso' },
  { format: NumberFormat.Riyal, title: 'Riyal' },
  { format: NumberFormat.Ringgit, title: 'Ringgit' },
  { format: NumberFormat.Leu, title: 'Leu' },
  { format: NumberFormat.ArgentinePeso, title: 'ArgentinePeso' },
  { format: NumberFormat.UruguayanPeso, title: 'UruguayanPeso' },
  { format: NumberFormat.Percent, title: 'Percent' },
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

  const changeNumberFormatClick = async (format: NumberFormat) => {
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
