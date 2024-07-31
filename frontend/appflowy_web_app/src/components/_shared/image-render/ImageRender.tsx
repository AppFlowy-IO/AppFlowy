import { Skeleton } from '@mui/material';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as ErrorOutline } from '@/assets/error.svg';

interface ImageRenderProps extends React.HTMLAttributes<HTMLImageElement> {
  src: string;
  alt?: string;
}

export function ImageRender({ src, ...props }: ImageRenderProps) {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  return (
    <>
      {hasError ? (
        <div className={'flex h-full w-full items-center justify-center gap-2 bg-red-50'}>
          <ErrorOutline className={'text-function-error'} />
          <div className={'text-function-error'}>{t('editor.imageLoadFailed')}</div>
        </div>
      ) : loading ? (
        <Skeleton variant='rectangular' width={'100%'} height={'100%'} />
      ) : null}
      <img
        style={{
          display: hasError ? 'none' : 'block',
          height: loading ? 0 : '100%',
          width: loading ? 1 : '100%',
        }}
        draggable={false}
        src={src}
        {...props}
        onLoad={(e) => {
          props.onLoad?.(e);
          setLoading(false);
          setHasError(false);
        }}
        onError={(e) => {
          props.onError?.(e);
          setHasError(true);
          setLoading(false);
        }}
      />
    </>
  );
}

export default ImageRender;
