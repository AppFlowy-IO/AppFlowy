import {
  CellProps,
  FileMediaCell as FileMediaCellType,
  FileMediaCellDataItem,
  FileMediaType,
} from '@/application/database-yjs/cell.type';
import { GalleryPreview } from '@/components/_shared/gallery-preview';
import PreviewImage from '@/components/database/components/cell/file-media/PreviewImage';
import UnPreviewFile from '@/components/database/components/cell/file-media/UnPreviewFile';

import React, { useCallback, useMemo, Suspense } from 'react';

export function FileMediaCell ({ cell, style, placeholder }: CellProps<FileMediaCellType>) {
  const value = cell?.data;
  const className = useMemo(() => {
    const classList = ['flex items-center gap-1.5 flex-wrap', 'cursor-text'];

    return classList.join(' ');
  }, []);
  const [openPreview, setOpenPreview] = React.useState(false);
  const previewIndexRef = React.useRef(0);
  const photos = useMemo(() => {
    return value?.filter(item => {
      return item.file_type === FileMediaType.Image;
    }).map(image => {
      return {
        src: image.url,
      };
    }) || [];
  }, [value]);

  const renderItem = useCallback((file: FileMediaCellDataItem, index: number) => {

    switch (file.file_type) {
      case FileMediaType.Image:
        return <PreviewImage
          key={file.id}
          file={file} onClick={() => {
          previewIndexRef.current = index;
          setOpenPreview(true);
        }}
        />;
      default:
        return <UnPreviewFile key={file.id} file={file} />;
    }
  }, []);

  const renderChildren = useMemo(() => {
    const length = value?.length || 0;

    if (length > 6) {
      return <>
        {value?.slice(0, 5).map(renderItem)}
        <div
          onClick={() => {
            previewIndexRef.current = 0;
            setOpenPreview(true);
          }}
          className={'flex items-center hover:scale-110 cursor-pointer justify-center w-fit aspect-square rounded-[8px] h-14 bg-gray-100 text-gray-500 text-sm'}
        >
          +{length - 5}
        </div>
      </>;
    }

    return value?.map(renderItem);
  }, [renderItem, value]);

  if (!value || value?.length === 0)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;

  return (
    <div style={style} className={className}>
      {renderChildren}
      {openPreview && <Suspense><GalleryPreview
        images={photos}
        previewIndex={previewIndexRef.current}
        open={openPreview}
        onClose={() => {
          setOpenPreview(false);
        }}
      /></Suspense>}
    </div>
  );
}

export default FileMediaCell;