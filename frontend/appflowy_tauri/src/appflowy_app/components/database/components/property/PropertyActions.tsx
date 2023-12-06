import React, { useMemo, useState } from 'react';

import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { ReactComponent as HideSvg } from '$app/assets/hide.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as LeftSvg } from '$app/assets/left.svg';
import { ReactComponent as RightSvg } from '$app/assets/right.svg';
import { useViewId } from '$app/hooks';
import { fieldService } from '$app/components/database/application';
import { CreateFieldPosition, FieldVisibility } from '@/services/backend';
import { MenuItem } from '@mui/material';
import ConfirmDialog from '$app/components/_shared/app-dialog/ConfirmDialog';
import { useTranslation } from 'react-i18next';

export enum FieldAction {
  EditProperty,
  Hide,
  Duplicate,
  Delete,
  InsertLeft,
  InsertRight,
}

const FieldActionSvgMap = {
  [FieldAction.EditProperty]: EditSvg,
  [FieldAction.Hide]: HideSvg,
  [FieldAction.Duplicate]: CopySvg,
  [FieldAction.Delete]: DeleteSvg,
  [FieldAction.InsertLeft]: LeftSvg,
  [FieldAction.InsertRight]: RightSvg,
};

const defaultActions: FieldAction[] = [
  FieldAction.EditProperty,
  FieldAction.InsertLeft,
  FieldAction.InsertRight,
  FieldAction.Hide,
  FieldAction.Duplicate,
  FieldAction.Delete,
];

// prevent default actions for primary fields
const primaryPreventDefaultActions = [FieldAction.Hide, FieldAction.Delete, FieldAction.Duplicate];

interface PropertyActionsProps {
  fieldId: string;
  actions?: FieldAction[];
  isPrimary?: boolean;
  onMenuItemClick?: (action: FieldAction, newFieldId?: string) => void;
}

function PropertyActions({ fieldId, onMenuItemClick, isPrimary, actions = defaultActions }: PropertyActionsProps) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [openConfirm, setOpenConfirm] = useState(false);

  const menuTextMap = useMemo(
    () => ({
      [FieldAction.EditProperty]: t('grid.field.editProperty'),
      [FieldAction.Hide]: t('grid.field.hide'),
      [FieldAction.Duplicate]: t('grid.field.duplicate'),
      [FieldAction.Delete]: t('grid.field.delete'),
      [FieldAction.InsertLeft]: t('grid.field.insertLeft'),
      [FieldAction.InsertRight]: t('grid.field.insertRight'),
    }),
    [t]
  );

  const handleOpenConfirm = () => {
    setOpenConfirm(true);
  };

  const handleMenuItemClick = async (action: FieldAction) => {
    const preventDefault = isPrimary && primaryPreventDefaultActions.includes(action);

    if (preventDefault) {
      return;
    }

    switch (action) {
      case FieldAction.EditProperty:
        break;
      case FieldAction.InsertLeft:
      case FieldAction.InsertRight: {
        const fieldPosition = action === FieldAction.InsertLeft ? CreateFieldPosition.Before : CreateFieldPosition.After;

        const field = await fieldService.createField({
          viewId,
          fieldPosition,
          targetFieldId: fieldId,
        });

        onMenuItemClick?.(action, field.id);
        return;
      }

      case FieldAction.Hide:
        await fieldService.updateFieldSetting(viewId, fieldId, {
          visibility: FieldVisibility.AlwaysHidden,
        });
        break;
      case FieldAction.Duplicate:
        await fieldService.duplicateField(viewId, fieldId);
        break;
      case FieldAction.Delete:
        handleOpenConfirm();
        return;
    }

    onMenuItemClick?.(action);
  };

  return (
    <>
      {actions.map((action) => {
        const ActionSvg = FieldActionSvgMap[action];
        const disabled = isPrimary && primaryPreventDefaultActions.includes(action);

        return (
          <MenuItem disabled={disabled} onClick={() => handleMenuItemClick(action)} key={action} dense>
            <ActionSvg className='mr-2 text-base' />
            {menuTextMap[action]}
          </MenuItem>
        );
      })}
      <ConfirmDialog
        open={openConfirm}
        subtitle={''}
        title={t('grid.field.deleteFieldPromptMessage')}
        onOk={async () => {
          await fieldService.deleteField(viewId, fieldId);
        }}
        onClose={() => {
          setOpenConfirm(false);
          onMenuItemClick?.(FieldAction.Delete);
        }}
      />
    </>
  );
}

export default PropertyActions;
