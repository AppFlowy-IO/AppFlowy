import { DocCoverType, YDoc } from '@/application/collab.type';
import { CoverType } from '@/application/folder-yjs/folder.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import { useBlockCover } from '@/components/document/document_header/useBlockCover';
import { showColorsForImage } from '@/components/document/document_header/utils';
import { renderColor } from '@/utils/color';
import React, { useCallback } from 'react';
import DefaultImage from './default_cover.jpg';

function DocumentCover({ doc, onTextColor }: { doc: YDoc; onTextColor: (color: string) => void }) {
  const viewId = useId().objectId;
  const { extra } = usePageInfo(viewId);

  const pageCover = extra.cover;
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

  if (!pageCover && !cover?.cover_selection) return null;
  return (
    <div className={`relative flex h-[255px] w-full max-sm:h-[180px]`}>
      {pageCover ? (
        <>
          {[CoverType.NormalColor, CoverType.GradientColor].includes(pageCover.type)
            ? renderCoverColor(pageCover.value)
            : null}
          {CoverType.BuildInImage === pageCover.type ? renderCoverImage(DefaultImage) : null}
          {[CoverType.CustomImage, CoverType.UpsplashImage].includes(pageCover.type)
            ? renderCoverImage(pageCover.value)
            : null}
        </>
      ) : cover?.cover_selection ? (
        <>
          {cover.cover_selection_type === DocCoverType.Asset ? renderCoverImage(DefaultImage) : null}
          {cover.cover_selection_type === DocCoverType.Color ? renderCoverColor(cover.cover_selection) : null}
          {cover.cover_selection_type === DocCoverType.Image ? renderCoverImage(cover.cover_selection) : null}
        </>
      ) : null}
    </div>
  );
}

export default DocumentCover;
