import {
  RowMeta,
  useDatabaseContext,
  useFieldsSelector,
  useRowMetaSelector,
} from '@/application/database-yjs';
import CardField from '@/components/database/components/field/CardField';
import React, { memo, useCallback, useEffect, useMemo } from 'react';
import { RowCoverType } from '@/application/types';
import { renderColor } from '@/utils/color';
import ImageRender from '@/components/_shared/image-render/ImageRender';

export interface CardProps {
  groupFieldId: string;
  rowId: string;
  onResize?: (height: number) => void;
  isDragging?: boolean;
}

export const Card = memo(({ groupFieldId, rowId, onResize, isDragging }: CardProps) => {
  const fields = useFieldsSelector();
  const meta = useRowMetaSelector(rowId);
  const cover = meta?.cover;
  const showFields = useMemo(() => fields.filter((field) => field.fieldId !== groupFieldId), [fields, groupFieldId]);

  const ref = React.useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (isDragging) return;
    const el = ref.current;

    if (!el) return;

    const observer = new ResizeObserver(() => {
      onResize?.(el.offsetHeight);
    });

    observer.observe(el);

    return () => {
      observer.disconnect();
    };
  }, [onResize, isDragging]);

  const navigateToRow = useDatabaseContext().navigateToRow;
  const className = useMemo(() => {
    const classList = ['relative board-card flex flex-col gap-2 overflow-hidden rounded-[6px] border border-line-card text-xs'];

    if (navigateToRow) {
      classList.push('cursor-pointer hover:bg-fill-list-hover');
    }

    return classList.join(' ');
  }, [navigateToRow]);

  const renderCoverImage = useCallback((cover: RowMeta['cover']) => {
    if (!cover) return null;

    if (cover.cover_type === RowCoverType.GradientCover || cover.cover_type === RowCoverType.ColorCover) {
      return <div
        style={{
          background: renderColor(cover.data),
        }}
        className={`h-full w-full`}
      />;
    }

    let url: string | undefined = cover.data;

    if (cover.cover_type === RowCoverType.AssetCover) {
      url = {
        1: '/covers/m_cover_image_1.png',
        2: '/covers/m_cover_image_2.png',
        3: '/covers/m_cover_image_3.png',
        4: '/covers/m_cover_image_4.png',
        5: '/covers/m_cover_image_5.png',
        6: '/covers/m_cover_image_6.png',
      }[Number(cover.data)];
    }

    if (!url) return null;

    return (
      <>
        <ImageRender
          draggable={false}
          src={url}
          alt={''}
          className={'h-full w-full object-cover'}
        />
      </>
    );
  }, []);

  return (
    <div
      onClick={() => {
        navigateToRow?.(rowId);
      }}
      ref={ref}
      className={className}
    >
      {cover && (
        <div
          className={'w-full h-[100px] bg-cover bg-center'}
        >
          {renderCoverImage(cover)}
        </div>
      )}
      <div className={'flex flex-col gap-2 py-2 px-3'}>
        {showFields.map((field, index) => {
          return <CardField
            index={index}
            key={field.fieldId}
            rowId={rowId}
            fieldId={field.fieldId}
          />;
        })}
      </div>

    </div>
  );
});

export default Card;
