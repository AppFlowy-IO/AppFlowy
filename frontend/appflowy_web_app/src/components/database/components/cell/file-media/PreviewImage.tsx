import { FileMediaCellDataItem } from '@/application/database-yjs/cell.type';
import React, { useMemo } from 'react';

function PreviewImage({ file, onClick }: { file: FileMediaCellDataItem; onClick: () => void }) {
  const thumb = useMemo(() => {
    const url = new URL(file.url);

    url.searchParams.set('auto', 'format');
    url.searchParams.set('fit', 'crop');

    return url.toString() + '&w=240&q=80';
  }, [file.url]);

  return (
    <div onClick={onClick} className={'transform cursor-pointer transition-all duration-200 hover:scale-110'}>
      <img
        src={thumb}
        alt={file.name}
        className={'aspect-square w-[60px] overflow-hidden rounded-[8px] border border-line-divider object-cover'}
      />
    </div>
  );
}

export default PreviewImage;
