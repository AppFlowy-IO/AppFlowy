import React, { useCallback, useState } from 'react';
import ImageList from '@mui/material/ImageList';
import ImageListItem from '@mui/material/ImageListItem';
import { AddOutlined } from '@mui/icons-material';
import { useTranslation } from 'react-i18next';

import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import ImageEdit from '$app/components/document/_shared/UploadImage/ImageEdit';
import GalleryItem, { Image } from '$app/components/document/DocumentBanner/cover/GalleryItem';

interface Props {
  onSelected: (image: Image) => void;
  images: Image[];
  onDelete: (image: Image) => Promise<void>;
  onAddImage: (url: string) => Promise<void>;
}
function GalleryList({ images, onSelected, onDelete, onAddImage }: Props) {
  const { t } = useTranslation();
  const [showEdit, setShowEdit] = useState(false);
  const onExitEdit = useCallback(() => {
    setShowEdit(false);
  }, []);

  return (
    <>
      <ImageList className={'max-h-[172px] w-full overflow-auto'} cols={4}>
        <ImageListItem>
          <div
            className={
              'm-1 flex h-[80px] w-[120px] cursor-pointer items-center justify-center rounded border border-fill-default bg-content-blue-50 text-fill-default hover:bg-content-blue-100'
            }
            onClick={() => setShowEdit(true)}
          >
            <AddOutlined />
          </div>
        </ImageListItem>
        {images.map((image) => {
          return (
            <GalleryItem
              key={image.url}
              image={image}
              onSelected={() => onSelected(image)}
              onDelete={() => onDelete(image)}
            />
          );
        })}
      </ImageList>
      <Dialog open={showEdit} onClose={onExitEdit} fullWidth>
        <DialogTitle>{t('button.upload')}</DialogTitle>
        <ImageEdit
          onSubmitUrl={async (url) => {
            await onAddImage(url);
            onExitEdit();
          }}
        />
      </Dialog>
    </>
  );
}

export default GalleryList;
