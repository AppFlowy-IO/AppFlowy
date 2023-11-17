import React, { MouseEvent, useCallback } from 'react';
import { Menu, MenuProps } from '@mui/material';
import FieldList from '$app/components/database/components/field/FieldList';
import { Field } from '$app/components/database/application';
import { useViewId } from '$app/hooks';
import { useTranslation } from 'react-i18next';
import { insertFilter } from '$app/components/database/application/filter/filter_service';
import { getDefaultFilter } from '$app/components/database/application/filter/filter_data';

function FilterFieldsMenu({
  onInserted,
  ...props
}: MenuProps & {
  onInserted?: () => void;
}) {
  const viewId = useViewId();
  const { t } = useTranslation();

  const addFilter = useCallback(
    async (event: MouseEvent, field: Field) => {
      const filterData = getDefaultFilter(field.type);

      if (!filterData) {
        return;
      }

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
    <Menu {...props}>
      <FieldList showSearch searchPlaceholder={t('grid.settings.filterBy')} onItemClick={addFilter} />
    </Menu>
  );
}

export default FilterFieldsMenu;
