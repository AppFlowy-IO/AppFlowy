import React from 'react';
import { Alert, CircularProgress } from '@mui/material';
import { ImageSvg } from '$app/components/_shared/svg/ImageSvg';
import { useTranslation } from 'react-i18next';

function ImagePlaceholder({
  error,
  loading,
  isEmpty,
  width,
  height,
  alignSelf,
  openPopover,
}: {
  error: boolean;
  loading: boolean;
  isEmpty: boolean;
  width?: number;
  height?: number;
  alignSelf: string;
  openPopover: () => void;
}) {
  const visible = loading || error || isEmpty;
  const { t } = useTranslation();

  return (
    <div
      style={{
        width: width ? width + 'px' : undefined,
        height: height ? height + 'px' : undefined,
        alignSelf,
        visibility: visible ? undefined : 'hidden',
      }}
      className={'absolute z-10 flex h-[100%] min-h-[59px] w-[100%] items-center justify-center'}
    >
      {loading && <CircularProgress />}
      {error && (
        <Alert className={'flex h-[100%] w-[100%] items-center justify-center'} severity='error'>
          Error loading image
        </Alert>
      )}
      {isEmpty && (
        <div
          onClick={openPopover}
          className={'flex h-[100%] w-[100%] flex-1 items-center rounded bg-content-blue-50 px-1 text-text-caption'}
        >
          <i className={'mx-2 h-5 w-5'}>
            <ImageSvg />
          </i>
          <span>{t('document.imageBlock.placeholder')}</span>
        </div>
      )}
    </div>
  );
}

export default ImagePlaceholder;
