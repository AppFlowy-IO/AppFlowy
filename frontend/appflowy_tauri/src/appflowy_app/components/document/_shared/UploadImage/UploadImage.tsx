import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ImageSvg } from '$app/components/_shared/svg/ImageSvg';
import { CircularProgress } from '@mui/material';
import { writeImage } from '$app/utils/document/image';
import { useTranslation } from 'react-i18next';
import { useMessage } from '$app/components/document/_shared/Message';

export interface UploadImageProps {
  onChange: (filePath: string) => void;
}

function UploadImage({ onChange }: UploadImageProps) {
  const { t } = useTranslation();
  const message = useMessage();

  const inputRef = useRef<HTMLInputElement>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const beforeUpload = useCallback(
    (file: File) => {
      // check file size and type
      const sizeMatched = file.size / 1024 / 1024 < 5; // 5MB
      const typeMatched = /image\/(png|jpg|jpeg|gif)/.test(file.type); // png, jpg, jpeg, gif

      if (!sizeMatched) {
        setError(t('document.imageBlock.error.invalidImageSize'));
      }

      if (!typeMatched) {
        setError(t('document.imageBlock.error.invalidImageFormat'));
      }

      return sizeMatched && typeMatched;
    },
    [t]
  );

  useEffect(() => {
    if (!error) return;
    message.show({
      message: error,
      duration: 3000,
      type: 'error',
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [error]);

  const handleUpload = useCallback(
    async (file: File) => {
      if (!file) return;
      if (!beforeUpload(file)) {
        return;
      }

      setError('');
      setLoading(true);
      // upload to tauri local data dir
      try {
        const filePath = await writeImage(file);

        setLoading(false);
        onChange(filePath);
      } catch {
        setLoading(false);
        setError(t('document.imageBlock.error.invalidImage'));
      }
    },
    [beforeUpload, onChange, t]
  );

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = e.target.files;

      if (!files || files.length === 0) return;
      const file = files[0];

      void handleUpload(file);
    },
    [handleUpload]
  );

  const handleDrop = useCallback(
    (e: React.DragEvent<HTMLDivElement>) => {
      e.preventDefault();
      const files = e.dataTransfer.files;

      if (!files || files.length === 0) return;
      const file = files[0];

      void handleUpload(file);
    },
    [handleUpload]
  );

  const handleDragOver = useCallback((e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  }, []);

  const errorColor = error ? '#FB006D' : undefined;

  return (
    <div className={'flex flex-col px-5 pt-5'}>
      <div
        className={'flex-1 cursor-pointer'}
        onClick={() => {
          if (loading) return;
          inputRef.current?.click();
        }}
        tabIndex={0}
      >
        <input onChange={handleChange} ref={inputRef} type='file' className={'hidden'} accept={'image/*'} />
        <div
          className={
            'flex flex-col items-center justify-center rounded-md border border-dashed border-content-blue-300 bg-content-blue-50 py-10 text-content-blue-300'
          }
          style={{
            borderColor: errorColor,
            background: error ? 'rgba(251, 0, 109, 0.08)' : undefined,
            color: errorColor,
          }}
          onDrop={handleDrop}
          onDragOver={handleDragOver}
        >
          <div className={'h-8 w-8'}>
            <ImageSvg />
          </div>
          <div className={'my-2 p-2'}>{t('document.imageBlock.upload.placeholder')}</div>
        </div>

        {loading ? <CircularProgress /> : null}
      </div>
      <div
        style={{
          color: errorColor,
        }}
        className={`mt-5 text-sm text-text-caption`}
      >
        {t('document.imageBlock.support')}
      </div>
      {message.contentHolder}
    </div>
  );
}

export default UploadImage;
