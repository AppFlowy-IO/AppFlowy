import React, { useMemo, useState } from 'react';
import Filter from '$app/components/database/components/filter/Filter';
import Button from '@mui/material/Button';
import FilterFieldsMenu from '$app/components/database/components/filter/FilterFieldsMenu';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useDatabase } from '$app/components/database';

function Filters() {
  const { t } = useTranslation();
  const { filters, fields } = useDatabase();

  const options = useMemo(() => {
    return filters.map((filter) => {
      const field = fields.find((field) => field.id === filter.fieldId);

      return {
        filter,
        field,
      };
    });
  }, [filters, fields]);

  const [filterAnchorEl, setFilterAnchorEl] = useState<null | HTMLElement>(null);
  const openAddFilterMenu = Boolean(filterAnchorEl);

  const handleClick = (e: React.MouseEvent<HTMLElement>) => {
    setFilterAnchorEl(e.currentTarget);
  };

  return (
    <div className={'flex items-center justify-center gap-[10px]'}>
      {options.map(({ filter, field }) => (field ? <Filter key={filter.id} filter={filter} field={field} /> : null))}
      <Button onClick={handleClick} color={'inherit'} startIcon={<AddSvg />}>
        {t('grid.settings.addFilter')}
      </Button>
      <FilterFieldsMenu
        keepMounted={false}
        open={openAddFilterMenu}
        anchorEl={filterAnchorEl}
        onClose={() => setFilterAnchorEl(null)}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
      />
    </div>
  );
}

export default Filters;
