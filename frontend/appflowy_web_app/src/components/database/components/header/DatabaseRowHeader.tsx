import { RowMeta, useCellSelector, usePrimaryFieldId, useRowMetaSelector } from '@/application/database-yjs';
import { AppendBreadcrumb, RowCoverType, ViewIconType, ViewLayout } from '@/application/types';
import Title from '@/components/database/components/header/Title';
import { getScrollParent } from '@/components/global-comment/utils';
import React, { useCallback, useEffect } from 'react';
import { renderColor } from '@/utils/color';
import ImageRender from '@/components/_shared/image-render/ImageRender';

function DatabaseRowHeader ({ rowId, appendBreadcrumb }: { rowId: string; appendBreadcrumb?: AppendBreadcrumb }) {
  const fieldId = usePrimaryFieldId() || '';

  const ref = React.useRef<HTMLDivElement>(null);
  const [offsetLeft, setOffsetLeft] = React.useState(0);
  const [width, setWidth] = React.useState<number | undefined>(undefined);
  const meta = useRowMetaSelector(rowId);
  const cover = meta?.cover;

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

  const cell = useCellSelector({
    rowId,
    fieldId,
  });

  useEffect(() => {
    appendBreadcrumb?.({
      children: [],
      extra: null, is_private: false, is_published: false, layout: ViewLayout.Document, view_id: rowId,
      name: cell?.data as string,
      icon: meta?.icon ? {
        ty: ViewIconType.Emoji,
        value: meta.icon,
      } : null,
    });

  }, [appendBreadcrumb, cell?.data, meta, rowId]);

  useEffect(() => {
    return () => {
      appendBreadcrumb?.(undefined);
    };
  }, [appendBreadcrumb]);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    const container = document.querySelector('.appflowy-scroll-container') || getScrollParent(el);

    if (!container) return;

    const handleResize = () => {
      setOffsetLeft(container.getBoundingClientRect().left - el.getBoundingClientRect().left);
      setWidth(container.getBoundingClientRect().width);
    };

    handleResize();
    const resizeObserver = new ResizeObserver(handleResize);

    resizeObserver.observe(container);

    return () => {
      resizeObserver.disconnect();
    };
  }, []);

  return <div
    ref={ref}
    className={'flex flex-col relative'}
  >
    <div
      className={'row-header-cover relative'}
      style={{ left: offsetLeft, width }}
    >
      {cover && <div
        style={{
          height: '40vh',
        }}
        className={'relative flex max-h-[288px] min-h-[130px] w-full max-sm:h-[180px]'}
      >
        {renderCoverImage(cover)}
      </div>}
    </div>
    <Title
      icon={meta?.icon}
      name={cell?.data as string}
    />
  </div>;
}

export default DatabaseRowHeader;
