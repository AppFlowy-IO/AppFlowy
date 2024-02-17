import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { deleteView } from '$app/application/database/database_view/database_view_service';
import { MenuItem, MenuProps, Menu } from '@mui/material';
import RenameDialog from '$app/components/_shared/confirm_dialog/RenameDialog';
import { Page } from '$app_reducers/pages/slice';
import { useAppDispatch } from '$app/stores/store';
import { updatePageName } from '$app_reducers/pages/async_actions';

enum ViewAction {
  Rename,
  Delete,
}

function ViewActions({ view, pageId, ...props }: { pageId: string; view: Page } & MenuProps) {
  const { t } = useTranslation();
  const viewId = view.id;
  const dispatch = useAppDispatch();
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
      disabled: viewId === pageId,
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
      <Menu keepMounted={false} disableRestoreFocus={true} {...props}>
        {options.map((option) => (
          <MenuItem disabled={option.disabled} key={option.id} onClick={option.action}>
            <div className={'mr-1.5'}>{option.icon}</div>
            {option.label}
          </MenuItem>
        ))}
      </Menu>
      {openRenameDialog && (
        <RenameDialog
          open={openRenameDialog}
          onClose={() => setOpenRenameDialog(false)}
          onOk={async (val) => {
            try {
              await dispatch(
                updatePageName({
                  id: viewId,
                  name: val,
                })
              );
              setOpenRenameDialog(false);
              props.onClose?.({}, 'backdropClick');
            } catch (e) {
              // toast.error(t('error.renameView'));
            }
          }}
          defaultValue={view.name}
        />
      )}
    </>
  );
}

export default ViewActions;
