import { useCellSelector, usePrimaryFieldId, useRowMetaSelector } from '@/application/database-yjs';
import { AppendBreadcrumb, ViewIconType, ViewLayout } from '@/application/types';
import Title from '@/components/database/components/header/Title';
import { getScrollParent } from '@/components/global-comment/utils';
import React, { useEffect } from 'react';

function DatabaseRowHeader ({ rowId, appendBreadcrumb }: { rowId: string; appendBreadcrumb?: AppendBreadcrumb }) {
  const fieldId = usePrimaryFieldId() || '';

  const ref = React.useRef<HTMLDivElement>(null);
  const [offsetLeft, setOffsetLeft] = React.useState(0);
  const [width, setWidth] = React.useState<number | undefined>(undefined);
  const meta = useRowMetaSelector(rowId);
  const cover = meta?.cover;

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

  return <div ref={ref} className={'flex flex-col relative'}>
    <div className={'row-header-cover relative'} style={{ left: offsetLeft, width }}>
      {cover && <img
        className={'max-h-[288px] min-h-[130px] w-full max-sm:h-[180px] object-cover'} src={cover}
        alt={cell?.data as string}
      />}
    </div>
    <Title icon={meta?.icon} name={cell?.data as string} />
  </div>;
}

export default DatabaseRowHeader;
