import { FileMediaCellDataItem, FileMediaType } from '@/application/database-yjs/cell.type';
import { ReactComponent as DocumentSvg } from '@/assets/document.svg';
import { ReactComponent as LinkSvg } from '@/assets/link.svg';
import { ReactComponent as CheckedSvg } from '@/assets/selected.svg';
import { ReactComponent as VideoSvg } from '@/assets/video.svg';
import { notify } from '@/components/_shared/notify';
import { copyTextToClipboard } from '@/utils/copy';
import { IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function UnPreviewFile ({ file }: { file: FileMediaCellDataItem }) {
  const { t } = useTranslation();
  const [clicked, setClicked] = React.useState(false);

  const handleClick = useCallback(() => {
    void copyTextToClipboard(file.url);
    setClicked(true);
    notify.success(t('grid.url.copy'));
  }, [file.url, t]);

  const renderIcon = useMemo(() => {
    switch (file.file_type) {
      case FileMediaType.Video:
        return <VideoSvg className={'w-5 h-5'} />;
      case FileMediaType.Link:
        return <LinkSvg className={'w-5 h-5'} />;
      default:
        return <DocumentSvg className={'w-5 h-5'} />;
    }
  }, [file.file_type]);

  return (
    <Tooltip
      title={
        clicked ? t('message.copy.success') : <div className={'flex gap-1.5'}>{renderIcon}{file.name}</div>
      } enterNextDelay={1000} placement={'bottom'}
    >
      <IconButton
        style={{
          border: '1px solid var(--line-divider)',
        }}
        className={'p-1 rounded-[8px]'}
        onMouseLeave={() => setClicked(false)}
        onClick={handleClick}
      >
        {clicked ? <CheckedSvg className={'text-fill-default w-5 h-5'} /> : renderIcon}
      </IconButton>
    </Tooltip>
  );
}

export default UnPreviewFile;