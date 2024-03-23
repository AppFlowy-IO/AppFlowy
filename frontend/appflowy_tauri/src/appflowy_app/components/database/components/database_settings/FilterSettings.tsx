import React, { useState } from 'react';
import { TextButton } from '$app/components/database/components/tab_bar/TextButton';
import { useTranslation } from 'react-i18next';
import { useFiltersCount } from '$app/components/database';
import FilterFieldsMenu from '$app/components/database/components/filter/FilterFieldsMenu';

function FilterSettings({ onToggleCollection }: { onToggleCollection: (forceOpen?: boolean) => void }) {
  const { t } = useTranslation();
  const filtersCount = useFiltersCount();
  const highlight = filtersCount > 0;
  const [filterAnchorEl, setFilterAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(filterAnchorEl);

  const handleClick = (e: React.MouseEvent<HTMLElement>) => {
    if (highlight) {
      onToggleCollection();
      return;
    }

    setFilterAnchorEl(e.currentTarget);
  };

  return (
    <>
      <TextButton className={'min-w-fit'} onClick={handleClick} color={highlight ? 'primary' : 'inherit'}>
        {t('grid.settings.filter')}
      </TextButton>
      <FilterFieldsMenu
        onInserted={() => onToggleCollection(true)}
        open={open}
        anchorEl={filterAnchorEl}
        onClose={() => setFilterAnchorEl(null)}
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

export default FilterSettings;
