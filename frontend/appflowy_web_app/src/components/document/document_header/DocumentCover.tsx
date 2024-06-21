import { showColorsForImage } from '@/components/document/document_header/utils';
import { renderColor } from '@/utils/color';
import React, { useCallback } from 'react';

function DocumentCover({
  coverValue,
  coverType,
  onTextColor,
}: {
  coverValue?: string;
  coverType?: string;
  onTextColor: (color: string) => void;
}) {
  const renderCoverColor = useCallback((color: string) => {
    return (
      <div
        style={{
          background: renderColor(color),
        }}
        className={`h-full w-full`}
      />
    );
  }, []);

  const renderCoverImage = useCallback(
    (url: string) => {
      return (
        <img
          onLoad={(e) => {
            void showColorsForImage(e.currentTarget).then((res) => {
              onTextColor(res);
            });
          }}
          draggable={false}
          src={url}
          alt={''}
          className={'h-full w-full object-cover'}
        />
      );
    },
    [onTextColor]
  );

  if (!coverType || !coverValue) {
    return null;
  }

  return (
    <div className={'relative flex h-[255px] w-full max-sm:h-[180px]'}>
      {coverType === 'color' && renderCoverColor(coverValue)}
      {(coverType === 'custom' || coverType === 'built_in') && renderCoverImage(coverValue)}
    </div>
  );
}

export default DocumentCover;
