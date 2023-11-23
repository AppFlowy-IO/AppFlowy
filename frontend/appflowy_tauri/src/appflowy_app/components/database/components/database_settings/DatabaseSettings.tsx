import React, { useState } from 'react';
import { Stack } from '@mui/material';
import { TextButton } from '$app/components/database/components/tab_bar/TextButton';
import { useTranslation } from 'react-i18next';

import SortSettings from '$app/components/database/components/database_settings/SortSettings';
import SettingsMenu from '$app/components/database/components/database_settings/SettingsMenu';
import FilterSettings from '$app/components/database/components/database_settings/FilterSettings';

interface Props {
  onToggleCollection: (forceOpen?: boolean) => void;
}

function DatabaseSettings(props: Props) {
  const { t } = useTranslation();
  const [settingAnchorEl, setSettingAnchorEl] = useState<null | HTMLElement>(null);

  return (
    <Stack className='text-neutral-500' direction='row' spacing='2px'>
      <FilterSettings {...props} />
      <SortSettings {...props} />
      <TextButton color='inherit' onClick={(e) => setSettingAnchorEl(e.currentTarget)}>
        {t('settings.title')}
      </TextButton>
      <SettingsMenu
        open={Boolean(settingAnchorEl)}
        anchorEl={settingAnchorEl}
        onClose={() => setSettingAnchorEl(null)}
      />
    </Stack>
  );
}

export default React.memo(DatabaseSettings);
