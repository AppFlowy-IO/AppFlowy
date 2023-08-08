import React, { useCallback, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

import GalleryList from '$app/components/document/DocumentBanner/cover/GalleryList';
import Button from '@mui/material/Button';
import { readCoverImageUrls, readImage, writeCoverImageUrls } from '$app/utils/document/image';
import { Log } from '$app/utils/log';
import { Image } from '$app/components/document/DocumentBanner/cover/GalleryItem';

function ChangeImages({ cover, onChange }: { onChange: (url: string) => void; cover: string }) {
  const { t } = useTranslation();
  const [images, setImages] = useState<Image[]>([]);
  const loadImageUrls = useCallback(async () => {
    try {
      const { images } = await readCoverImageUrls();
      const newImages = [];

      for (const image of images) {
        try {
          const src = await readImage(image.url);

          newImages.push({ ...image, src });
        } catch (e) {
          Log.error(e);
        }
      }

      setImages(newImages);
    } catch (e) {
      Log.error(e);
    }
  }, [setImages]);

  const onAddImage = useCallback(
    async (url: string) => {
      const { images } = await readCoverImageUrls();

      await writeCoverImageUrls([...images, { url }]);
      await loadImageUrls();
    },
    [loadImageUrls]
  );

  const onDelete = useCallback(
    async (image: Image) => {
      const { images } = await readCoverImageUrls();
      const newImages = images.filter((i) => i.url !== image.url);

      await writeCoverImageUrls(newImages);
      await loadImageUrls();
    },
    [loadImageUrls]
  );

  const onClearAll = useCallback(async () => {
    await writeCoverImageUrls([]);
    await loadImageUrls();
  }, [loadImageUrls]);

  useEffect(() => {
    loadImageUrls();
  }, [loadImageUrls]);

  return (
    <div className={'flex w-[500px] flex-col'}>
      <div className={'flex justify-between pb-2 pl-2 pt-4 text-text-caption'}>
        <div>{t('document.plugins.cover.images')}</div>
        <Button onClick={onClearAll}>{t('document.plugins.cover.clearAll')}</Button>
      </div>
      <GalleryList
        images={images}
        onDelete={onDelete}
        onAddImage={onAddImage}
        onSelected={(image) => onChange(image.url)}
      />
    </div>
  );
}

export default ChangeImages;
