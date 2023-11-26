import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { deleteView, updateView } from '$app/components/database/application/database_view/database_view_service';
import { MenuItem, MenuProps, Menu } from '@mui/material';
import RenameDialog from '$app/components/layout/NestedPage/RenameDialog';
import { Page } from '$app_reducers/pages/slice';

enum ViewAction {
  Rename,
  Delete,
}

function ViewActions({ view, ...props }: { view: Page } & MenuProps) {
  const { t } = useTranslation();
  const viewId = view.id;
  const [openRenameDialog, setOpenRenameDialog] = useState(false);
  const options = [
    {
      id: ViewAction.Rename,
      label: t('button.rename'),
      icon: <EditSvg />,
      action: () => {
        setOpenRenameDialog(true);
      },
    },

    {
      id: ViewAction.Delete,
      label: t('button.delete'),
      icon: <DeleteSvg />,
      action: async () => {
        try {
          await deleteView(viewId);
          props.onClose?.({}, 'backdropClick');
        } catch (e) {
          // toast.error(t('error.deleteView'));
        }
      },
    },
  ];

  return (
    <>
      <Menu keepMounted={false} {...props}>
        {options.map((option) => (
          <MenuItem key={option.id} onClick={option.action}>
            <div className={'mr-1.5'}>{option.icon}</div>
            {option.label}
          </MenuItem>
        ))}
      </Menu>
      <RenameDialog
        open={openRenameDialog}
        onClose={() => setOpenRenameDialog(false)}
        onOk={async (val) => {
          try {
            await updateView(viewId, {
              name: val,
            });
            setOpenRenameDialog(false);
            props.onClose?.({}, 'backdropClick');
          } catch (e) {
            // toast.error(t('error.renameView'));
          }
        }}
        defaultValue={view.name}
      />
    </>
  );
}

export default ViewActions;
