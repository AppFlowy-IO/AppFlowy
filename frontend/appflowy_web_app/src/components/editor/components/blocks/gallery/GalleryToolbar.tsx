import { IconButton, Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CopyIcon } from '@/assets/link.svg';
import { ReactComponent as DownloadIcon } from '@/assets/download.svg';
import { ReactComponent as PreviewIcon } from '@/assets/full_view.svg';

function GalleryToolbar ({
  onOpenPreview,
  onDownload,
  onCopy,
}: {
  onOpenPreview: () => void;
  onDownload: () => void;
  onCopy: () => void;
}) {
  const { t } = useTranslation();
  const buttons = useMemo(() => [
    { label: t('gallery.preview'), onClick: onOpenPreview, Icon: PreviewIcon },
    { label: t('gallery.copy'), onClick: onCopy, Icon: CopyIcon },
    { label: t('gallery.download'), onClick: onDownload, Icon: DownloadIcon },
  ], [t, onOpenPreview, onDownload, onCopy]);

  return (
    <div className={'absolute z-10 top-0 right-0'}>
      <div className={'flex space-x-1 rounded-[8px] p-1 bg-bg-body shadow border border-line-divider '}>
        {buttons.map(({ label, onClick, Icon }, index) => (
          <Tooltip title={label} key={index}>
            <IconButton
              size={'small'} onClick={onClick}
              className={'p-1 hover:bg-transparent hover:text-content-blue-400'}
            >
              <Icon className={'h-5 w-5'} />
            </IconButton>
          </Tooltip>
        ))}
      </div>
    </div>
  );
}

export default GalleryToolbar;