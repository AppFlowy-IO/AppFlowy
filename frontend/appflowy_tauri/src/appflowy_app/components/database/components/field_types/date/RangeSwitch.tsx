import React from 'react';
import { Switch, SwitchProps } from '@mui/material';
import { useTranslation } from 'react-i18next';
import Typography from '@mui/material/Typography';
import { ReactComponent as DateSvg } from '$app/assets/database/field-type-date.svg';

function RangeSwitch({
  checked,
  onIsRangeChange,
  ...props
}: SwitchProps & {
  onIsRangeChange: (checked: boolean) => void;
}) {
  const { t } = useTranslation();
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onIsRangeChange(event.target.checked);
  };

  return (
    <div className={'flex w-full items-center justify-between gap-[20px]'}>
      <div className={'flex flex-1 justify-start gap-1.5'}>
        <DateSvg />
        <Typography className={'flex-1 text-xs font-medium'}>{t('grid.field.isRange')}</Typography>
      </div>
      <Switch {...props} size={'small'} checked={checked} onChange={handleChange} />
    </div>
  );
}

export default RangeSwitch;
