import React, { useCallback } from 'react';
import { MenuProps } from '@mui/material';
import PropertiesList from '$app/components/database/components/property/PropertiesList';
import { Field } from '$app/application/database';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { insertFilter } from '$app/application/database/filter/filter_service';
import { getDefaultFilter } from '$app/application/database/filter/filter_data';
import Popover from '@mui/material/Popover';

function FilterFieldsMenu({
  onInserted,
  ...props
}: MenuProps & {
  onInserted?: () => void;
}) {
  const viewId = useViewId();
  const { t } = useTranslation();

  const addFilter = useCallback(
    async (field: Field) => {
      const filterData = getDefaultFilter(field.type);

      await insertFilter({
        viewId,
        fieldId: field.id,
        fieldType: field.type,
        data: filterData,
      });
      props.onClose?.({}, 'backdropClick');
      onInserted?.();
    },
    [props, viewId, onInserted]
  );

  return (
    <Popover
      onKeyDown={(e) => {
        if (e.key === 'Escape') {
          e.preventDefault();
          e.stopPropagation();
          props.onClose?.({}, 'escapeKeyDown');
        }
      }}
      {...props}
    >
      <PropertiesList
        onClose={() => {
          props.onClose?.({}, 'escapeKeyDown');
        }}
        showSearch
        searchPlaceholder={t('grid.settings.filterBy')}
        onItemClick={addFilter}
      />
    </Popover>
  );
}

export default FilterFieldsMenu;
