import { Popover } from '@/components/_shared/popover';
import { Button, Divider } from '@mui/material';
import React from 'react';
import { ReactComponent as LockIcon } from '@/assets/space_permission_private.svg';
import { ReactComponent as PublicIcon } from '@/assets/space_permission_public.svg';
import { ReactComponent as DropdownIcon } from '@/assets/space_permission_dropdown.svg';
import { ReactComponent as SelectedIcon } from '@/assets/selected.svg';
import { useTranslation } from 'react-i18next';
import { SpacePermission } from '@/application/types';

function SpacePermissionButton ({
  onSelected,
  value,
}: {
  value: SpacePermission;
  onSelected?: (permission: SpacePermission) => void;
}) {
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const { t } = useTranslation();

  return (
    <>
      <Button
        size={'large'}
        className={'justify-start gap-4 py-3'}
        startIcon={SpacePermission.Private === value ? <LockIcon /> : <PublicIcon />}
        endIcon={<DropdownIcon />}
        color={'inherit'}
        variant={'outlined'}
        onClick={e => setAnchorEl(e.currentTarget)}
      >
        <div className={'flex w-full items-start flex-col'}>
          <div className={'text-base font-normal'}>{
            SpacePermission.Private === value ? t('space.privatePermission') : t('space.publicPermission')
          }</div>
          <div className={'text-text-caption'}>{
            SpacePermission.Private === value ? t('space.privatePermissionDescription') : t('space.publicPermissionDescription')
          }</div>
        </div>
      </Button>
      <Popover
        open={Boolean(anchorEl)}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(null)}
      >
        <div
          style={{
            width: anchorEl?.clientWidth,
          }}
          className={'flex flex-col gap-2 p-2'}
        >
          <Button
            className={'justify-start gap-2 px-4'}
            startIcon={<LockIcon />}
            color={'inherit'}
            onClick={() => {
              onSelected?.(SpacePermission.Private);
              setAnchorEl(null);
            }}
          >
            <div className={'flex w-full items-start flex-col'}>
              <div className={'text-base font-normal'}>{t('space.privatePermission')}</div>
              <div className={'text-text-caption'}>{t('space.privatePermissionDescription')}</div>
            </div>
            {SpacePermission.Private === value &&
              <SelectedIcon className={'w-6 h-6 text-function-success'} />}

          </Button>
          <Divider />
          <Button
            className={'justify-start gap-2 px-4'}
            startIcon={<PublicIcon />}
            color={'inherit'}
            onClick={() => {
              onSelected?.(SpacePermission.Public);
              setAnchorEl(null);
            }}
          >
            <div className={'flex w-full items-start flex-col'}>
              <div className={'text-base font-normal'}>{t('space.publicPermission')}</div>
              <div className={'text-text-caption'}>{t('space.publicPermissionDescription')}</div>
            </div>
            {SpacePermission.Public === value &&
              <SelectedIcon className={'w-6 h-6 text-function-success'} />}

          </Button>
        </div>
      </Popover>
    </>
  );
}

export default SpacePermissionButton;