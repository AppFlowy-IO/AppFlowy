import React, { useCallback, useRef, useState } from 'react';
import { ImageSvg } from '$app/components/_shared/svg/ImageSvg';
import { CircularProgress } from '@mui/material';
import { writeImage } from '$app/utils/document/image';
import { isTauri } from '$app/utils/env';

export interface UploadImageProps {
  onChange: (filePath: string) => void;
}

function UploadImage({ onChange }: UploadImageProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const beforeUpload = useCallback((file: File) => {
    // check file size and type
    const sizeMatched = file.size / 1024 / 1024 < 5; // 5MB
    const typeMatched = /image\/(png|jpg|jpeg|gif)/.test(file.type); // png, jpg, jpeg, gif

    return sizeMatched && typeMatched;
  }, []);

  const handleUpload = useCallback(
    async (file: File) => {
      if (!file) return;
      if (!beforeUpload(file)) {
        setError('Image should be less than 5MB and in png, jpg, jpeg, gif format');
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
        setError('Upload failed');
      }
    },
    [beforeUpload, onChange]
  );

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = e.target.files;

      if (!files || files.length === 0) return;
      const file = files[0];

      handleUpload(file);
    },
    [handleUpload]
  );

  const handleDrop = useCallback(
    (e: React.DragEvent<HTMLDivElement>) => {
      e.preventDefault();
      const files = e.dataTransfer.files;

      if (!files || files.length === 0) return;
      const file = files[0];

      handleUpload(file);
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
            'flex flex-col items-center justify-center rounded-md border border-dashed border-main-accent bg-main-selector py-10 text-main-accent'
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
          <div className={'my-2 p-2'}>{isTauri() ? 'Click space to chose image' : 'Chose image or drag to space'}</div>
        </div>

        {loading ? <CircularProgress /> : null}
      </div>
      <div
        style={{
          color: errorColor,
        }}
        className={`mt-5 text-sm text-shade-3`}
      >
        The maximum file size is 5MB. Supported formats: JPG, PNG, GIF, SVG.
      </div>
    </div>
  );
}

export default UploadImage;
