import React from 'react';
import { useTranslation } from 'react-i18next';
import FontSizeConfig from '$app/components/layout/TopBar/FontSizeConfig';
import { Divider } from '@mui/material';
import { useLocation } from 'react-router-dom';
import { useMoreOptionsConfig } from '$app/components/layout/TopBar/MoreOptions.hooks';

function MoreOptions() {
  const { t } = useTranslation();
  const { showStyleOptions } = useMoreOptionsConfig();

  return <div className={'flex w-[220px] flex-col'}>{showStyleOptions && <FontSizeConfig />}</div>;
}

export default MoreOptions;
