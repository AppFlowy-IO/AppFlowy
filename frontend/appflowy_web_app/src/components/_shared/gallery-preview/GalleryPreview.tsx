import { notify } from '@/components/_shared/notify';
import { copyTextToClipboard } from '@/utils/copy';
import { IconButton, Portal, Tooltip } from '@mui/material';
import React, { memo, useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { TransformWrapper, TransformComponent } from 'react-zoom-pan-pinch';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';
import { ReactComponent as ReloadIcon } from '@/assets/reload.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as MinusIcon } from '@/assets/minus.svg';
import { ReactComponent as LinkIcon } from '@/assets/link.svg';
import { ReactComponent as DownloadIcon } from '@/assets/download.svg';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

export interface GalleryImage {
  src: string;
  thumb: string;
  responsive: string;
}

export interface GalleryPreviewProps {
  images: GalleryImage[];
  open: boolean;
  onClose: () => void;
  previewIndex: number;
}

const buttonClassName = 'p-1 hover:bg-transparent text-white hover:text-content-blue-400 p-0';

function GalleryPreview ({
  images,
  open,
  onClose,
  previewIndex,
}: GalleryPreviewProps) {
  const { t } = useTranslation();
  const [index, setIndex] = useState(previewIndex);
  const handleToPrev = useCallback(() => {
    setIndex((prev) => prev === 0 ? images.length - 1 : prev - 1);
  }, [images.length]);

  const handleToNext = useCallback(() => {
    setIndex((prev) => prev === images.length - 1 ? 0 : prev + 1);
  }, [images.length]);

  const handleCopy = useCallback(async () => {
    const image = images[index];

    if (!image) {
      return;
    }

    await copyTextToClipboard(image.src);
    notify.success(t('publish.copy.imageBlock'));
  }, [images, index, t]);

  const handleDownload = useCallback(() => {
    const image = images[index];

    if (!image) {
      return;
    }

    window.open(image.src, '_blank');
  }, [images, index]);

  const handleKeydown = useCallback((e: KeyboardEvent) => {
    e.preventDefault();
    e.stopPropagation();
    switch (true) {
      case e.key === 'ArrowLeft':
      case e.key === 'ArrowUp':
        handleToPrev();
        break;
      case e.key === 'ArrowRight':
      case e.key === 'ArrowDown':
        handleToNext();
        break;
      case e.key === 'Escape':
        onClose();
        break;
    }
  }, [handleToNext, handleToPrev, onClose]);

  useEffect(() => {
    (document.activeElement as HTMLElement)?.blur();
    window.addEventListener('keydown', handleKeydown);

    return () => {
      window.removeEventListener('keydown', handleKeydown);
    };
  }, [handleKeydown]);

  if (!open) {
    return null;
  }

  return (
    <Portal container={document.body}>
      <div className={'fixed inset-0 bg-black bg-opacity-80 z-50'} onClick={onClose}>

        <TransformWrapper
          initialScale={1}
          centerOnInit={true}
          maxScale={1.5}
          minScale={0.5}
        >
          {({ zoomIn, zoomOut, resetTransform }) => (
            <React.Fragment>
              <div className="absolute bottom-20 left-1/2 z-10 transform flex gap-4 -translate-x-1/2 p-4"
                   onClick={e => e.stopPropagation()}
              >
                {images.length > 1 &&
                  <div className={'flex gap-2 w-fit bg-bg-mask rounded-[8px] p-2'}>
                    <Tooltip title={t('gallery.prev')}>
                      <IconButton size={'small'} onClick={handleToPrev} className={buttonClassName}>
                        <RightIcon className={'transform rotate-180'} />
                      </IconButton>
                    </Tooltip>
                    <span className={'text-text-caption'}>{index + 1}/{images.length}</span>
                    <Tooltip title={t('gallery.next')}>
                      <IconButton size={'small'} onClick={handleToNext} className={buttonClassName}>
                        <RightIcon />
                      </IconButton>
                    </Tooltip>
                  </div>}
                <div className={'flex items-center gap-2 w-fit  bg-bg-mask rounded-[8px] p-2'}>
                  <Tooltip title={t('gallery.zoomIn')}>
                    <IconButton size={'small'} onClick={() => zoomIn()} className={buttonClassName}>
                      <AddIcon />
                    </IconButton>
                  </Tooltip>
                  {/*<Button color={'inherit'} size={'small'}>*/}
                  {/*  {scale * 100}%*/}
                  {/*</Button>*/}
                  <Tooltip title={t('gallery.zoomOut')}>
                    <IconButton size={'small'} onClick={() => zoomOut()} className={buttonClassName}>
                      <MinusIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title={t('gallery.resetZoom')}>
                    <IconButton size={'small'} onClick={() => resetTransform()} className={buttonClassName}>
                      <ReloadIcon />
                    </IconButton>
                  </Tooltip>
                </div>
                <div className={'flex gap-2 w-fit  bg-bg-mask rounded-[8px] p-2'}>
                  <Tooltip title={t('gallery.copy')}>
                    <IconButton size={'small'} className={buttonClassName} onClick={handleCopy}>
                      <LinkIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title={t('button.download')}>
                    <IconButton size={'small'} className={buttonClassName} onClick={handleDownload}>
                      <DownloadIcon />
                    </IconButton>
                  </Tooltip>

                </div>
                <Tooltip title={t('button.close')}>
                  <IconButton
                    size={'small'} onClick={onClose}
                    className={'bg-bg-mask px-3.5 rounded-[8px] text-white hover:text-content-blue-400'}
                  >
                    <CloseIcon className={'w-3.5 h-3.5'} />
                  </IconButton>
                </Tooltip>
              </div>
              <TransformComponent contentProps={{
                onClick: e => e.stopPropagation(),
              }} wrapperStyle={{ width: '100%', height: '100%' }}
              >
                <img src={images[index].src} alt={images[index].src}
                />
              </TransformComponent>
            </React.Fragment>
          )}
        </TransformWrapper>
      </div>
    </Portal>
  );
}

export default memo(GalleryPreview);