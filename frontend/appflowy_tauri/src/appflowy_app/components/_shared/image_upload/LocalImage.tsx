import React, { forwardRef, useCallback, useEffect, useRef, useState } from 'react';
import { CircularProgress } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ErrorOutline } from '@mui/icons-material';

export const LocalImage = forwardRef<
  HTMLImageElement,
  {
    renderErrorNode?: () => React.ReactElement | null;
  } & React.ImgHTMLAttributes<HTMLImageElement>
>((localImageProps, ref) => {
  const { src, renderErrorNode, ...props } = localImageProps;
  const imageRef = useRef<HTMLImageElement>(null);
  const { t } = useTranslation();
  const [imageURL, setImageURL] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [isError, setIsError] = useState<boolean>(false);
  const loadLocalImage = useCallback(async () => {
    if (!src) return;
    setLoading(true);
    setIsError(false);
    const { readBinaryFile, BaseDirectory } = await import('@tauri-apps/api/fs');

    try {
      const svg = src.endsWith('.svg');

      const buffer = await readBinaryFile(src, { dir: BaseDirectory.AppLocalData });
      const blob = new Blob([buffer], { type: svg ? 'image/svg+xml' : 'image' });

      setImageURL(URL.createObjectURL(blob));
    } catch (e) {
      setIsError(true);
    }

    setLoading(false);
  }, [src]);

  useEffect(() => {
    void loadLocalImage();
  }, [loadLocalImage]);

  if (loading) {
    return (
      <div className={`flex h-full w-full items-center justify-center gap-2`}>
        <CircularProgress size={16} />
        {t('editor.loading')}...
      </div>
    );
  }

  if (isError) {
    if (renderErrorNode) return renderErrorNode();
    return (
      <div className={'flex h-full w-full items-center justify-center gap-2 bg-red-50'}>
        <ErrorOutline className={'text-function-error'} />
        <div className={'text-function-error'}>{t('editor.imageLoadFailed')}</div>
      </div>
    );
  }

  return <img ref={ref ?? imageRef} draggable={false} loading={'lazy'} alt={'local image'} {...props} src={imageURL} />;
});
