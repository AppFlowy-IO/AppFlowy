import { Grid, MenuItem } from '@mui/material';
import { t } from 'i18next';

import { ReactComponent as HideSvg } from '$app/assets/hide.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as LeftSvg } from '$app/assets/left.svg';
import { ReactComponent as RightSvg } from '$app/assets/right.svg';
import { fieldService } from '$app/components/database/application';
import { FieldVisibility } from '@/services/backend';
import { useViewId } from '$app/hooks';
import ConfirmDialog from '$app/components/_shared/app-dialog/ConfirmDialog';
import { useState } from 'react';

enum FieldAction {
  Hide = 'hide',
  Duplicate = 'duplicate',
  Delete = 'delete',
  InsertLeft = 'insertLeft',
  InsertRight = 'insertRight',
}

const FieldActionSvgMap = {
  [FieldAction.Hide]: HideSvg,
  [FieldAction.Duplicate]: CopySvg,
  [FieldAction.Delete]: DeleteSvg,
  [FieldAction.InsertLeft]: LeftSvg,
  [FieldAction.InsertRight]: RightSvg,
};

const TwoColumnActions: FieldAction[][] = [
  [FieldAction.Hide, FieldAction.Duplicate, FieldAction.Delete],
  // [FieldAction.InsertLeft, FieldAction.InsertRight],
];

// prevent default actions for primary fields
const primaryPreventDefaultActions = [FieldAction.Delete, FieldAction.Duplicate];

interface GridFieldMenuActionsProps {
  fieldId: string;
  isPrimary?: boolean;
  onMenuItemClick?: (action: FieldAction) => void;
}

export const FieldMenuActions = ({ fieldId, onMenuItemClick, isPrimary }: GridFieldMenuActionsProps) => {
  const viewId = useViewId();
  const [openConfirm, setOpenConfirm] = useState(false);

  const handleOpenConfirm = () => {
    setOpenConfirm(true);
  };

  const handleMenuItemClick = async (action: FieldAction) => {
    const preventDefault = isPrimary && primaryPreventDefaultActions.includes(action);

    if (preventDefault) {
      return;
    }

    switch (action) {
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
    <Grid container columns={TwoColumnActions.length} spacing={2}>
      {TwoColumnActions.map((column, index) => (
        <Grid key={index} item xs={6}>
          {column.map((action) => {
            const ActionSvg = FieldActionSvgMap[action];
            const disabled = isPrimary && primaryPreventDefaultActions.includes(action);

            return (
              <MenuItem disabled={disabled} onClick={() => handleMenuItemClick(action)} key={action} dense>
                <ActionSvg className='mr-2 text-base' />
                {t(`grid.field.${action}`)}
              </MenuItem>
            );
          })}
        </Grid>
      ))}
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
    </Grid>
  );
};
