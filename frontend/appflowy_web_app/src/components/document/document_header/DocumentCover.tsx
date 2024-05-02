import { CoverType, YDoc } from '@/application/collab.type';
import { useBlockCover } from '@/components/document/document_header/useBlockCover';
import { renderColor } from '@/utils/color';
import React, { useCallback } from 'react';
import DefaultImage from './default_cover.jpg';

function DocumentCover({ doc }: { doc: YDoc }) {
  const { cover } = useBlockCover(doc);
  const renderCoverColor = useCallback((color: string) => {
    return (
      <div
        style={{
          backgroundColor: renderColor(color),
        }}
        className={`h-full w-full`}
      />
    );
  }, []);

  const renderCoverImage = useCallback((url: string) => {
    return <img draggable={false} src={url} alt={''} className={'h-full w-full object-cover'} />;
  }, []);

  const { cover_selection_type: type, cover_selection: value = '' } = cover || {};

  return value ? (
    <div className={`relative mb-[-80px] flex h-[255px] w-full`}>
      <>
        {type === CoverType.Asset ? renderCoverImage(DefaultImage) : null}
        {type === CoverType.Color ? renderCoverColor(value) : null}
        {type === CoverType.Image ? renderCoverImage(value) : null}
      </>
    </div>
  ) : null;
}

export default DocumentCover;
