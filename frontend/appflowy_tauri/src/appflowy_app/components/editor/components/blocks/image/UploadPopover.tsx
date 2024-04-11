import React, { useMemo } from 'react';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';

import { useTranslation } from 'react-i18next';
import { EmbedLink, Unsplash, UploadTabs, TabOption, TAB_KEY, UploadImage } from '$app/components/_shared/image_upload';
import { CustomEditor } from '$app/components/editor/command';
import { useSlateStatic } from 'slate-react';
import { ImageNode, ImageType } from '$app/application/document/document.types';

const initialOrigin: {
  transformOrigin: PopoverOrigin;
  anchorOrigin: PopoverOrigin;
} = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'center',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'center',
  },
};

function UploadPopover({
  open,
  anchorEl,
  onClose,
  node,
}: {
  open: boolean;
  anchorEl: HTMLDivElement | null;
  onClose: () => void;
  node: ImageNode;
}) {
  const editor = useSlateStatic();

  const { t } = useTranslation();

  const { transformOrigin, anchorOrigin, isEntered, paperHeight, paperWidth } = usePopoverAutoPosition({
    initialPaperWidth: 433,
    initialPaperHeight: 300,
    anchorEl,
    initialAnchorOrigin: initialOrigin.anchorOrigin,
    initialTransformOrigin: initialOrigin.transformOrigin,
    open,
  });

  const tabOptions: TabOption[] = useMemo(() => {
    return [
      {
        label: t('button.upload'),
        key: TAB_KEY.UPLOAD,
        Component: UploadImage,
        onDone: (link: string) => {
          CustomEditor.setImageBlockData(editor, node, {
            url: link,
            image_type: ImageType.Local,
          });
          onClose();
        },
      },
      {
        label: t('document.imageBlock.embedLink.label'),
        key: TAB_KEY.EMBED_LINK,
        Component: EmbedLink,
        onDone: (link: string) => {
          CustomEditor.setImageBlockData(editor, node, {
            url: link,
            image_type: ImageType.External,
          });
          onClose();
        },
      },
      {
        key: TAB_KEY.UNSPLASH,
        label: t('document.imageBlock.unsplash.label'),
        Component: Unsplash,
        onDone: (link: string) => {
          CustomEditor.setImageBlockData(editor, node, {
            url: link,
            image_type: ImageType.External,
          });
          onClose();
        },
      },
    ];
  }, [editor, node, onClose, t]);

  return (
    <UploadTabs
      popoverProps={{
        anchorEl,
        open: open && isEntered,
        onClose,
        transformOrigin,
        anchorOrigin,
        onMouseDown: (e) => {
          e.stopPropagation();
        },
      }}
      containerStyle={{
        maxWidth: paperWidth,
        maxHeight: paperHeight,
        overflow: 'hidden',
      }}
      tabOptions={tabOptions}
    />
  );
}

export default UploadPopover;
