import React, { FC, MouseEvent, useCallback } from 'react';
import { Menu, MenuProps } from '@mui/material';
import FieldList from '$app/components/database/components/field/FieldList';
import { Field, sortService } from '$app/components/database/application';
import { SortConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import { useViewId } from '$app/hooks';

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
    <Menu keepMounted={false} {...props}>
      <FieldList showSearch={true} onItemClick={addSort} searchPlaceholder={t('grid.settings.sortBy')} />
    </Menu>
  );
};

export default SortFieldsMenu;
