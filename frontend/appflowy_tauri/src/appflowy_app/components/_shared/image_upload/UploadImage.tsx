import React, { useCallback } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import CloudUploadIcon from '@mui/icons-material/CloudUploadOutlined';
import { notify } from '$app/components/_shared/notify';
import { isTauri } from '$app/utils/env';
import { getFileName, IMAGE_DIR, ALLOWED_IMAGE_EXTENSIONS, MAX_IMAGE_SIZE } from '$app/utils/upload_image';

export function UploadImage({ onDone }: { onDone?: (url: string) => void }) {
  const { t } = useTranslation();

  const checkTauriFile = useCallback(
    async (url: string) => {
      // const { readBinaryFile } = await import('@tauri-apps/api/fs');
      // const buffer = await readBinaryFile(url);
      // const blob = new Blob([buffer]);
      // if (blob.size > MAX_IMAGE_SIZE) {
      //   notify.error(t('document.imageBlock.error.invalidImageSize'));
      //   return false;
      // }

      return true;
    },
    [t]
  );

  const uploadTauriLocalImage = useCallback(
    async (url: string) => {
      const { copyFile, BaseDirectory, exists, createDir } = await import('@tauri-apps/api/fs');

      const checked = await checkTauriFile(url);

      if (!checked) return;

      try {
        const existDir = await exists(IMAGE_DIR, { dir: BaseDirectory.AppLocalData });

        if (!existDir) {
          await createDir(IMAGE_DIR, { dir: BaseDirectory.AppLocalData });
        }

        const filename = getFileName(url);

        await copyFile(url, `${IMAGE_DIR}/${filename}`, { dir: BaseDirectory.AppLocalData });
        const newUrl = `${IMAGE_DIR}/${filename}`;

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
          extensions: ALLOWED_IMAGE_EXTENSIONS,
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
