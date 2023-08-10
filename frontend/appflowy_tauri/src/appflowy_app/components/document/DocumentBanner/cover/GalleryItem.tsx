import React, { useState } from 'react';
import { DeleteOutlineRounded } from '@mui/icons-material';
import ImageListItem from '@mui/material/ImageListItem';

export interface Image {
  url: string;
  src?: string;
}
function GalleryItem({ image, onSelected, onDelete }: { image: Image; onSelected: () => void; onDelete: () => void }) {
  const [hover, setHover] = useState(false);

  return (
    <ImageListItem
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      className={'flex items-center justify-center '}
      key={image.url}
    >
      <div className={'flex h-[80px] w-[120px] cursor-pointer items-center justify-center  overflow-hidden rounded'}>
        <img
          style={{
            objectFit: 'cover',
            width: '100%',
            height: '100%',
          }}
          onClick={onSelected}
          src={`${image.src}`}
          alt={image.url}
        />
      </div>

      <div
        style={{
          display: hover ? 'block' : 'none',
        }}
        className={'absolute right-2 top-2'}
      >
        <button className={'rounded bg-bg-body opacity-80 hover:opacity-100'} onClick={() => onDelete()}>
          <DeleteOutlineRounded />
        </button>
      </div>
    </ImageListItem>
  );
}

export default GalleryItem;
