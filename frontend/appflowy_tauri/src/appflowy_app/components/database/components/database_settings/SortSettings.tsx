import React from 'react';
import { useTranslation } from 'react-i18next';
import { useDatabase } from '$app/components/database';
import { TextButton } from '$app/components/database/components/tab_bar/TextButton';
import SortFieldsMenu from '$app/components/database/components/sort/SortFieldsMenu';

interface Props {
  onToggleCollection: (forceOpen?: boolean) => void;
}

function SortSettings({ onToggleCollection }: Props) {
  const { t } = useTranslation();
  const { sorts } = useDatabase();

  const highlight = sorts && sorts.length > 0;

  const [sortAnchorEl, setSortAnchorEl] = React.useState<null | HTMLElement>(null);
  const open = Boolean(sortAnchorEl);
  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    if (highlight) {
      onToggleCollection();
      return;
    }

    setSortAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setSortAnchorEl(null);
  };

  return (
    <>
      <TextButton className={'min-w-fit p-1'} color={highlight ? 'primary' : 'inherit'} onClick={handleClick}>
        {t('grid.settings.sort')}
      </TextButton>
      <SortFieldsMenu
        onInserted={() => onToggleCollection(true)}
        open={open}
        anchorEl={sortAnchorEl}
        onClose={handleClose}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
      />
    </>
  );
}

export default SortSettings;
