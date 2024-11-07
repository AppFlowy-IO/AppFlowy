import { notify } from '@/components/_shared/notify';
import React, { useCallback, useRef } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CloudUploadIcon } from '@/assets/cloud_add.svg';

export const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
export const ALLOWED_IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];

export function getFileName (url: string) {
  const [...parts] = url.split('/');

  return parts.pop() ?? url;
}

export function UploadImage ({ onDone }: { onDone?: (url: string) => void }) {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const handleClickUpload = useCallback(async () => {
    if (!inputRef.current) return;

    inputRef.current.click();
  }, []);

  const handleFileChange = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (file.size > MAX_IMAGE_SIZE) {
      notify.error('File size is too large, please upload a file less than 10MB');

      return;
    }

  }, []);

  return (
    <div className={'w-full px-4 pb-4'}>
      <Button
        component="label"
        role={undefined}
        tabIndex={-1}
        variant={'outlined'}
        startIcon={<CloudUploadIcon />}
        className={'w-full'}
        color={'inherit'}
        onClick={handleClickUpload}
      >
        {t('document.imageBlock.upload.placeholder')}
      </Button>

      <input
        ref={inputRef}
        type={'file'}
        accept={ALLOWED_IMAGE_EXTENSIONS.join(',')}
        style={{ display: 'none' }}
        onChange={handleFileChange}
      />
    </div>
  );
}

export default UploadImage;
