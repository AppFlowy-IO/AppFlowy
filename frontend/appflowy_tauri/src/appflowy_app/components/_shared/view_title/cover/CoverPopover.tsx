import React, { useMemo } from 'react';
import { CoverType, PageCover } from '$app_reducers/pages/slice';
import { PopoverOrigin } from '@mui/material/Popover';
import { EmbedLink, Unsplash, UploadTabs, TabOption, TAB_KEY, UploadImage } from '$app/components/_shared/image_upload';
import { useTranslation } from 'react-i18next';
import Colors from '$app/components/_shared/view_title/cover/Colors';
import { ImageType } from '$app/application/document/document.types';
import Button from '@mui/material/Button';

const initialOrigin: {
  anchorOrigin: PopoverOrigin;
  transformOrigin: PopoverOrigin;
} = {
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
};

function CoverPopover({
  anchorEl,
  open,
  onClose,
  onUpdateCover,
  onRemoveCover,
}: {
  anchorEl: HTMLElement | null;
  open: boolean;
  onClose: () => void;
  onUpdateCover?: (cover?: PageCover) => void;
  onRemoveCover?: () => void;
}) {
  const { t } = useTranslation();
  const tabOptions: TabOption[] = useMemo(() => {
    return [
      {
        label: t('document.plugins.cover.colors'),
        key: TAB_KEY.Colors,
        Component: Colors,
        onDone: (value: string) => {
          onUpdateCover?.({
            cover_selection_type: CoverType.Color,
            cover_selection: value,
            image_type: ImageType.Internal,
          });
        },
      },
      {
        label: t('button.upload'),
        key: TAB_KEY.UPLOAD,
        Component: UploadImage,
        onDone: (value: string) => {
          onUpdateCover?.({
            cover_selection_type: CoverType.Image,
            cover_selection: value,
            image_type: ImageType.Local,
          });
          onClose();
        },
      },
      {
        label: t('document.imageBlock.embedLink.label'),
        key: TAB_KEY.EMBED_LINK,
        Component: EmbedLink,
        onDone: (value: string) => {
          onUpdateCover?.({
            cover_selection_type: CoverType.Image,
            cover_selection: value,
            image_type: ImageType.External,
          });
          onClose();
        },
      },
      {
        key: TAB_KEY.UNSPLASH,
        label: t('document.imageBlock.unsplash.label'),
        Component: Unsplash,
        onDone: (value: string) => {
          onUpdateCover?.({
            cover_selection_type: CoverType.Image,
            cover_selection: value,
            image_type: ImageType.External,
          });
        },
      },
    ];
  }, [onClose, onUpdateCover, t]);

  return (
    <UploadTabs
      popoverProps={{
        anchorEl,
        open,
        onClose,
        ...initialOrigin,
      }}
      containerStyle={{ width: 433, maxHeight: 300 }}
      tabOptions={tabOptions}
      extra={
        <Button color={'inherit'} size={'small'} className={'mr-4'} variant={'text'} onClick={onRemoveCover}>
          {t('button.remove')}
        </Button>
      }
    />
  );
}

export default CoverPopover;
