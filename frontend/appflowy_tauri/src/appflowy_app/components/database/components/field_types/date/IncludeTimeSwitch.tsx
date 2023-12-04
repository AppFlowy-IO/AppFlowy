import React from 'react';
import { Switch, SwitchProps } from '@mui/material';
import { ReactComponent as TimeSvg } from '$app/assets/database/field-type-last-edited-time.svg';
import Typography from '@mui/material/Typography';
import { useTranslation } from 'react-i18next';

function IncludeTimeSwitch({
  checked,
  onIncludeTimeChange,
  ...props
}: SwitchProps & {
  onIncludeTimeChange: (checked: boolean) => void;
}) {
  const { t } = useTranslation();
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onIncludeTimeChange(event.target.checked);
  };

  return (
    <div className={'flex w-full items-center justify-between gap-[20px]'}>
      <div className={'flex flex-1 justify-start gap-1.5'}>
        <TimeSvg />
        <Typography className={'flex-1 text-xs font-medium'}>{t('grid.field.includeTime')}</Typography>
      </div>
      <Switch {...props} size={'small'} checked={checked} onChange={handleChange} />
    </div>
  );
}

export default IncludeTimeSwitch;
