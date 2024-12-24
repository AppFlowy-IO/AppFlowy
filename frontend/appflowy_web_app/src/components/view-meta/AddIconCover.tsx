import { ViewIconType } from '@/application/types';
import ChangeIconPopover from '@/components/_shared/view-icon/ChangeIconPopover';
import { Button } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddIcon } from '@/assets/add_icon.svg';
import { ReactComponent as AddCover } from '@/assets/add_cover.svg';

function AddIconCover({
  hasIcon,
  hasCover,
  onUpdateIcon,
  onAddCover,
  iconAnchorEl,
  setIconAnchorEl,
  maxWidth,
  visible,
}: {
  visible: boolean;
  hasIcon: boolean;
  hasCover: boolean;
  onUpdateIcon?: (icon: { ty: ViewIconType, value: string }) => void;
  onAddCover?: () => void;
  iconAnchorEl: HTMLElement | null;
  setIconAnchorEl: (el: HTMLElement | null) => void;
  maxWidth?: number;
}) {
  const { t } = useTranslation();

  return (
    <>
      <div
        style={{
          width: maxWidth ? `${maxWidth}px` : '100%',
          visibility: visible ? 'visible' : 'hidden',
        }}
        className={'max-sm:px-6 px-24 flex items-end min-w-0 max-w-full gap-2 justify-start max-sm:hidden'}
      >
        {!hasIcon && <Button
          color={'inherit'}
          size={'small'}
          onClick={e => {
            setIconAnchorEl(e.currentTarget);
          }}
          startIcon={<AddIcon/>}
        >{t('document.plugins.cover.addIcon')}</Button>}
        {!hasCover && <Button
          size={'small'}
          color={'inherit'}
          onClick={onAddCover}
          startIcon={<AddCover/>}
        >{t('document.plugins.cover.addCover')}</Button>}

      </div>
      <ChangeIconPopover
        open={Boolean(iconAnchorEl)}
        anchorEl={iconAnchorEl}
        onClose={() => {
          setIconAnchorEl(null);
        }}
        defaultType={'emoji'}
        iconEnabled={true}
        onSelectIcon={(icon) => {
          setIconAnchorEl(null);
          if (icon.ty === ViewIconType.Icon) {
            onUpdateIcon?.({
              ty: ViewIconType.Icon,
              value: JSON.stringify({
                color: icon.color,
                groupName: icon.value.split('/')[0],
                iconName: icon.value.split('/')[1],
                iconContent: icon.content,
              }),
            });
            return;
          }

          onUpdateIcon?.(icon);
        }}
        removeIcon={() => {
          setIconAnchorEl(null);
          onUpdateIcon?.({ ty: ViewIconType.Emoji, value: '' });
        }}
      />
    </>

  );
}

export default AddIconCover;