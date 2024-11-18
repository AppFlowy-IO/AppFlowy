import { SpacePermission } from '@/application/types';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers } from '@/components/app/app.hooks';
import SpaceIconButton from '@/components/app/view-actions/SpaceIconButton';
import SpacePermissionButton from '@/components/app/view-actions/SpacePermissionButton';
import { OutlinedInput } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';

function CreateSpaceModal ({ open, onClose }: {
  open: boolean;
  onClose: () => void;
}) {
  const [spaceName, setSpaceName] = React.useState<string>('');
  const [spaceIcon, setSpaceIcon] = React.useState<string>('');
  const [spaceIconColor, setSpaceIconColor] = React.useState<string>('');
  const [spacePermission, setSpacePermission] = React.useState<SpacePermission>(SpacePermission.Public);
  const [loading, setLoading] = React.useState<boolean>(false);
  const { t } = useTranslation();
  const { createSpace } = useAppHandlers();
  const handleOk = async () => {
    if (!createSpace) return;
    setLoading(true);
    try {
      await createSpace({
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

  return (
    <NormalModal
      keepMounted={false}
      okText={t('button.save')}
      cancelText={t('button.cancel')}
      open={open}
      onClose={onClose}
      title={
        t('space.createNewSpace')
      }
      okLoading={loading}
      onOk={handleOk}
      PaperProps={{
        className: 'w-[600px] max-w-[70vw]',
      }}
    >
      <div className={'flex flex-col gap-4'}>
        <div className={'flex flex-col justify-center items-center gap-3'}>
          <div className={'text-text-caption text-center font-normal'}>{t('space.createSpaceDescription')}</div>
          <SpaceIconButton
            spaceIcon={spaceIcon}
            spaceIconColor={spaceIconColor}
            spaceName={spaceName}
            size={60}
            onSelectSpaceIcon={setSpaceIcon}
            onSelectSpaceIconColor={setSpaceIconColor}
          />
        </div>
        <div className={'flex flex-col gap-2'}>
          <div className={'text-text-caption'}>{t('space.spaceName')}</div>
          <OutlinedInput
            value={spaceName}
            fullWidth={true}
            onChange={(e) => setSpaceName(e.target.value)}
            size={'small'}
            placeholder={t('space.spaceNamePlaceholder')}
          />
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

export default CreateSpaceModal;