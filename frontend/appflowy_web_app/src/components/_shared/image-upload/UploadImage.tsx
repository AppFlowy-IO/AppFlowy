import FileDropzone from '@/components/_shared/file-dropzone/FileDropzone';
import { notify } from '@/components/_shared/notify';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';

export const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
export const ALLOWED_IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];

export function UploadImage ({ onDone }: { onDone?: (url: string) => void }) {
  const { t } = useTranslation();
  const handleFileChange = useCallback(async (files: File[]) => {
    const file = files[0];

    if (!file) return;

    if (file.size > MAX_IMAGE_SIZE) {
      notify.error('File size is too large, please upload a file less than 10MB');

      return;
    }

    onDone?.(URL.createObjectURL(file));

  }, [onDone]);

  return (
    <div className={'px-4 pb-4'}>
      <FileDropzone
        placeholder={t('fileDropzone.dropFile')}
        onChange={handleFileChange}
        accept={ALLOWED_IMAGE_EXTENSIONS.join(',')}
      />
    </div>

  );
}

export default UploadImage;
