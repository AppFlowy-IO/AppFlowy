import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { deleteView } from '$app/application/database/database_view/database_view_service';
import { MenuProps, Menu } from '@mui/material';
import RenameDialog from '$app/components/_shared/confirm_dialog/RenameDialog';
import { Page } from '$app_reducers/pages/slice';
import { useAppDispatch } from '$app/stores/store';
import { updatePageName } from '$app_reducers/pages/async_actions';
import KeyboardNavigation from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

enum ViewAction {
  Rename,
  Delete,
}

function ViewActions({ view, pageId, ...props }: { pageId: string; view: Page } & MenuProps) {
  const { t } = useTranslation();
  const viewId = view.id;
  const dispatch = useAppDispatch();
  const [openRenameDialog, setOpenRenameDialog] = useState(false);
  const renderContent = useCallback((title: string, Icon: React.FC<React.SVGProps<SVGSVGElement>>) => {
    return (
      <div className={'flex w-full items-center gap-1'}>
        <Icon className={'h-4 w-4'} />
        <div className={'flex-1'}>{title}</div>
      </div>
    );
  }, []);

  const onConfirm = useCallback(
    async (key: ViewAction) => {
      switch (key) {
        case ViewAction.Rename:
          setOpenRenameDialog(true);
          break;
        case ViewAction.Delete:
          try {
            await deleteView(viewId);
            props.onClose?.({}, 'backdropClick');
          } catch (e) {
            // toast.error(t('error.deleteView'));
          }

          break;
        default:
          break;
      }
    },
    [viewId, props]
  );
  const options = [
    {
      key: ViewAction.Rename,
      content: renderContent(t('button.rename'), EditSvg),
    },

    {
      key: ViewAction.Delete,
      content: renderContent(t('button.delete'), DeleteSvg),
      disabled: viewId === pageId,
    },
  ];

  return (
    <>
      <Menu keepMounted={false} disableRestoreFocus={true} {...props}>
        <KeyboardNavigation
          options={options}
          onConfirm={onConfirm}
          onEscape={() => {
            props.onClose?.({}, 'escapeKeyDown');
          }}
        />
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
                  immediate: true,
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
