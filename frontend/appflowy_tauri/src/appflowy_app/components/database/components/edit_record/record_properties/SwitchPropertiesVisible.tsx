import React from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { ReactComponent as EyeClosedSvg } from '$app/assets/eye_close.svg';
import { ReactComponent as EyeOpenSvg } from '$app/assets/eye_open.svg';

function SwitchPropertiesVisible({
  hiddenFieldsCount,
  showHiddenFields,
  setShowHiddenFields,
}: {
  hiddenFieldsCount: number;
  showHiddenFields: boolean;
  setShowHiddenFields: (showHiddenFields: boolean) => void;
}) {
  const { t } = useTranslation();

  return hiddenFieldsCount > 0 ? (
    <Button
      onClick={() => {
        setShowHiddenFields(!showHiddenFields);
      }}
      className={'w-full justify-start'}
      startIcon={showHiddenFields ? <EyeClosedSvg /> : <EyeOpenSvg />}
      color={'inherit'}
    >
      {showHiddenFields
        ? t('grid.rowPage.hideHiddenFields', {
            count: hiddenFieldsCount,
          })
        : t('grid.rowPage.showHiddenFields', {
            count: hiddenFieldsCount,
          })}
    </Button>
  ) : null;
}

export default SwitchPropertiesVisible;
