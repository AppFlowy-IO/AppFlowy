import React, { FC, MouseEvent, useCallback } from 'react';
import { MenuProps } from '@mui/material';
import PropertiesList from '$app/components/database/components/property/PropertiesList';
import { Field, sortService } from '$app/components/database/application';
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
    async (event: MouseEvent, field: Field) => {
      await sortService.insertSort(viewId, {
        fieldId: field.id,
        fieldType: field.type,
        condition: SortConditionPB.Ascending,
      });
      props.onClose?.({}, 'backdropClick');
      onInserted?.();
    },
    [props, viewId, onInserted]
  );

  return (
    <Popover keepMounted={false} {...props}>
      <PropertiesList showSearch={true} onItemClick={addSort} searchPlaceholder={t('grid.settings.sortBy')} />
    </Popover>
  );
};

export default SortFieldsMenu;
