import { SpacePermission } from '@/application/types';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useAppView } from '@/components/app/app.hooks';
import SpaceIconButton from '@/components/app/view-actions/SpaceIconButton';
import SpacePermissionButton from '@/components/app/view-actions/SpacePermissionButton';
import { OutlinedInput } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';

function ManageSpace ({ open, onClose, viewId }: {
  open: boolean;
  onClose: () => void;
  viewId: string;
}) {
  const view = useAppView(viewId);
  const [spaceName, setSpaceName] = React.useState<string>(view?.name || '');
  const [spaceIcon, setSpaceIcon] = React.useState<string>(view?.extra?.space_icon || '');
  const [spaceIconColor, setSpaceIconColor] = React.useState<string>(view?.extra?.space_icon_color || '');
  const [spacePermission, setSpacePermission] = React.useState<SpacePermission>(view?.is_private ? SpacePermission.Private : SpacePermission.Public);

  const [loading, setLoading] = React.useState<boolean>(false);
  const { t } = useTranslation();
  const { updateSpace } = useAppHandlers();

  const handleOk = async () => {
    if (!updateSpace) return;
    setLoading(true);
    try {
      await updateSpace({
        view_id: viewId,
        name: spaceName,
        space_icon: spaceIcon,
        space_icon_color: spaceIconColor,
        space_permission: spacePermission,
      });
      onClose();
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  };

  if (!view) return null;
  return (
    <NormalModal
      keepMounted={false}
      okText={t('button.save')}
      cancelText={t('button.cancel')}
      open={open}
      onClose={onClose}
      title={
        t('space.manage')
      }
      okLoading={loading}
      onOk={handleOk}
      PaperProps={{
        className: 'w-[500px] max-w-[70vw]',
      }}
    >
      <div className={'flex flex-col gap-4'}>
        <div className={'flex flex-col gap-2'}>
          <div className={'text-text-caption'}>{t('space.spaceName')}</div>
          <div className={'flex items-center gap-3'}>
            <SpaceIconButton
              spaceIcon={spaceIcon}
              spaceIconColor={spaceIconColor}
              spaceName={spaceName}
              onSelectSpaceIcon={setSpaceIcon}
              onSelectSpaceIconColor={setSpaceIconColor}
            />
            <OutlinedInput
              value={spaceName}
              fullWidth={true}
              onChange={(e) => setSpaceName(e.target.value)}
              size={'small'}
              placeholder={t('space.spaceNamePlaceholder')}
            />
          </div>
        </div>
        <div className={'flex flex-col gap-2'}>
          <div className={'text-text-caption'}>{t('space.permission')}</div>
          <SpacePermissionButton
            onSelected={setSpacePermission}
            value={spacePermission}
          />
        </div>
      </div>

    </NormalModal>
  );
}

export default ManageSpace;