import { FileMediaCellDataItem } from '@/application/database-yjs/cell.type';
import React, { useMemo } from 'react';

function PreviewImage ({ file, onClick }: { file: FileMediaCellDataItem, onClick: () => void }) {
  const thumb = useMemo(() => {
    const url = new URL(file.url);

    url.searchParams.set('auto', 'format');
    url.searchParams.set('fit', 'crop');

    return url.toString() + '&w=240&q=80';
  }, [file.url]);

  return (
    <div onClick={onClick} className={'p-1 cursor-pointer hover:scale-110 transform transition-all duration-200'}>
      <img
        src={thumb} alt={file.name}
        className={'w-fit h-full object-cover border border-line-divider rounded-[8px] overflow-hidden'}
      />
    </div>
  );
}

export default PreviewImage;