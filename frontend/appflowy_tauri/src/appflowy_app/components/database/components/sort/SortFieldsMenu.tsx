import React, { FC, useCallback } from 'react';
import { MenuProps } from '@mui/material';
import PropertiesList from '$app/components/database/components/property/PropertiesList';
import { Field, sortService } from '$app/application/database';
import { SortConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { useViewId } from '$app/hooks';
import Popover from '@mui/material/Popover';

const SortFieldsMenu: FC<
  MenuProps & {
    onInserted?: () => void;
  }
> = ({ onInserted, ...props }) => {
  const { t } = useTranslation();
  const viewId = useViewId();
  const addSort = useCallback(
    async (field: Field) => {
      await sortService.insertSort(viewId, {
        fieldId: field.id,
        condition: SortConditionPB.Ascending,
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
      keepMounted={false}
      {...props}
    >
      <PropertiesList
        onClose={() => {
          props.onClose?.({}, 'escapeKeyDown');
        }}
        showSearch={true}
        onItemClick={addSort}
        searchPlaceholder={t('grid.settings.sortBy')}
      />
    </Popover>
  );
};

export default SortFieldsMenu;
