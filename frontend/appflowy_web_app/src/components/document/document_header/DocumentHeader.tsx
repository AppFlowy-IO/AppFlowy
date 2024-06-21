import { DocCoverType, YDoc, YjsFolderKey } from '@/application/collab.type';
import { useViewSelector } from '@/application/folder-yjs';
import { CoverType } from '@/application/folder-yjs/folder.type';
import { usePageInfo } from '@/components/_shared/page/usePageInfo';
import DocumentCover from '@/components/document/document_header/DocumentCover';
import { useBlockCover } from '@/components/document/document_header/useBlockCover';
import React, { memo, useMemo, useRef, useState } from 'react';
import BuiltInImage1 from '@/assets/cover/m_cover_image_1.png';
import BuiltInImage2 from '@/assets/cover/m_cover_image_2.png';
import BuiltInImage3 from '@/assets/cover/m_cover_image_3.png';
import BuiltInImage4 from '@/assets/cover/m_cover_image_4.png';
import BuiltInImage5 from '@/assets/cover/m_cover_image_5.png';
import BuiltInImage6 from '@/assets/cover/m_cover_image_6.png';

export function DocumentHeader({ viewId, doc }: { viewId: string; doc: YDoc }) {
  const ref = useRef<HTMLDivElement>(null);
  const { view } = useViewSelector(viewId);
  const [textColor, setTextColor] = useState<string>('var(--text-title)');
  const icon = view?.get(YjsFolderKey.icon);
  const iconObject = useMemo(() => {
    try {
      return JSON.parse(icon || '');
    } catch (e) {
      return null;
    }
  }, [icon]);

  const { extra } = usePageInfo(viewId);

  const pageCover = extra.cover;
  const { cover } = useBlockCover(doc);

  const coverType = useMemo(() => {
    if (
      (pageCover && [CoverType.NormalColor, CoverType.GradientColor].includes(pageCover.type)) ||
      cover?.cover_selection_type === DocCoverType.Color
    ) {
      return 'color';
    }

    if (CoverType.BuildInImage === pageCover?.type || cover?.cover_selection_type === DocCoverType.Asset) {
      return 'built_in';
    }

    if (
      (pageCover && [CoverType.CustomImage, CoverType.UpsplashImage].includes(pageCover.type)) ||
      cover?.cover_selection_type === DocCoverType.Image
    ) {
      return 'custom';
    }
  }, [cover?.cover_selection_type, pageCover]);

  const coverValue = useMemo(() => {
    if (coverType === 'built_in') {
      return {
        1: BuiltInImage1,
        2: BuiltInImage2,
        3: BuiltInImage3,
        4: BuiltInImage4,
        5: BuiltInImage5,
        6: BuiltInImage6,
      }[pageCover?.value as string];
    }

    return pageCover?.value || cover?.cover_selection;
  }, [coverType, cover?.cover_selection, pageCover]);

  return (
    <div ref={ref} className={'document-header mb-[10px] select-none'}>
      <div className={'view-banner relative flex w-full flex-col overflow-hidden'}>
        <DocumentCover onTextColor={setTextColor} coverType={coverType} coverValue={coverValue} />

        <div className={`relative mx-16 w-[964px] min-w-0 max-w-full overflow-visible max-md:mx-4`}>
          <div
            style={{
              position: coverValue ? 'absolute' : 'relative',
              bottom: '100%',
              width: '100%',
            }}
            className={'flex items-center gap-2 px-14 py-8 text-4xl max-md:px-2 max-sm:text-[7vw]'}
          >
            <div className={`view-icon`}>{iconObject?.value}</div>
            <div className={'flex flex-1 items-center gap-2 overflow-hidden'}>
              <div
                style={{
                  color: textColor,
                }}
                className={'font-bold leading-[1.5em]'}
              >
                {view?.get(YjsFolderKey.name)}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default memo(DocumentHeader);
