import { ViewIconType } from '@/application/types';
import ChangeIconPopover from '@/components/_shared/view-icon/ChangeIconPopover';
import { Button } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddIcon } from '@/assets/add_icon.svg';
import { ReactComponent as AddCover } from '@/assets/add_cover.svg';

function AddIconCover ({
  hasIcon,
  hasCover,
  onUpdateIcon,
  onAddCover,
  iconAnchorEl,
  setIconAnchorEl,

}: {
  hasIcon: boolean;
  hasCover: boolean;
  onUpdateIcon?: (icon: { ty: ViewIconType, value: string }) => void;
  onAddCover?: () => void;
  iconAnchorEl: HTMLElement | null;
  setIconAnchorEl: (el: HTMLElement | null) => void;
}) {
  const { t } = useTranslation();

  return (
    <div className={'gap-2 flex w-full justify-start items-center px-24 max-sm:hidden'}>
      {!hasIcon && <Button
        color={'inherit'}
        size={'small'}
        onClick={e => {
          setIconAnchorEl(e.currentTarget);
        }}
        startIcon={<AddIcon />}
      >{t('document.plugins.cover.addIcon')}</Button>}
      {!hasCover && <Button
        size={'small'}
        color={'inherit'}
        onClick={onAddCover}
        startIcon={<AddCover />}
      >{t('document.plugins.cover.addCover')}</Button>}
      <ChangeIconPopover
        open={Boolean(iconAnchorEl)}
        anchorEl={iconAnchorEl}
        onClose={() => {
          setIconAnchorEl(null);
        }}
        defaultType={'emoji'}
        iconEnabled={false}
        onSelectIcon={(icon) => {
          setIconAnchorEl(null);
          onUpdateIcon?.(icon);
        }}
        removeIcon={() => {
          setIconAnchorEl(null);
          onUpdateIcon?.({ ty: ViewIconType.Emoji, value: '' });
        }}
      />
    </div>
  );
}

export default AddIconCover;