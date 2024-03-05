import React, { useCallback } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import CloudUploadIcon from '@mui/icons-material/CloudUploadOutlined';
import { notify } from '$app/components/_shared/notify';
import { isTauri } from '$app/utils/env';

const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB

export function UploadImage({ onDone }: { onDone?: (url: string) => void }) {
  const { t } = useTranslation();

  const checkTauriFile = useCallback(
    async (url: string) => {
      const filename = url.split('/').pop();

      if (!filename) return false;

      const filetype = filename.split('.').pop();

      if (!filetype || ['jpg', 'jpeg', 'png'].indexOf(filetype) === -1) {
        notify.error(t('document.imageBlock.error.invalidImageFormat'));
        return false;
      }

      const { readBinaryFile } = await import('@tauri-apps/api/fs');

      const buffer = await readBinaryFile(url);
      const blob = new Blob([buffer], { type: filetype });

      if (blob.size > MAX_IMAGE_SIZE) {
        notify.error(t('document.imageBlock.error.invalidImageSize'));
        return false;
      }

      return true;
    },
    [t]
  );

  const uploadTauriLocalImage = useCallback(
    async (url: string) => {
      const { copyFile, BaseDirectory, exists, createDir } = await import('@tauri-apps/api/fs');

      const filename = url.split('/').pop();

      if (!filename) return;

      const checked = await checkTauriFile(url);

      if (!checked) return;

      try {
        const existDir = await exists('images', { dir: BaseDirectory.AppLocalData });

        if (!existDir) {
          await createDir('images', { dir: BaseDirectory.AppLocalData });
        }

        await copyFile(url, `images/${filename}`, { dir: BaseDirectory.AppLocalData });
        const newUrl = `images/${filename}`;

        onDone?.(newUrl);
      } catch (e) {
        notify.error(t('document.plugins.image.imageUploadFailed'));
      }
    },
    [checkTauriFile, onDone, t]
  );

  const handleClickUpload = useCallback(async () => {
    if (!isTauri()) return;
    const { open } = await import('@tauri-apps/api/dialog');

    const url = await open({
      multiple: false,
      directory: false,
      filters: [
        {
          name: 'Image',
          extensions: ['jpg', 'jpeg', 'png'],
        },
      ],
    });

    if (!url || typeof url !== 'string') return;

    await uploadTauriLocalImage(url);
  }, [uploadTauriLocalImage]);

  return (
    <div className={'w-full px-4 pb-4'}>
      <Button
        component='label'
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
    </div>
  );
}

export default UploadImage;
