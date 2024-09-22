import { DatabaseContext, useFieldsSelector, useRowMetaSelector } from '@/application/database-yjs';
import CardField from '@/components/database/components/field/CardField';
import React, { memo, useContext, useEffect, useMemo } from 'react';

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

  const navigateToRow = useContext(DatabaseContext)?.navigateToRow;
  const className = useMemo(() => {
    const classList = ['relative shadow-sm flex flex-col gap-2 overflow-hidden rounded-[8px] border border-line-divider text-xs'];

    if (navigateToRow) {
      classList.push('cursor-pointer hover:bg-fill-list-hover');
    }

    return classList.join(' ');
  }, [navigateToRow]);

  return (
    <div
      onClick={() => {
        navigateToRow?.(rowId);
      }}
      ref={ref}
      style={{
        minHeight: '38px',
      }}
      className={className}
    >
      {cover && (
        <div
          className={'w-full h-[100px] bg-cover bg-center'}
        >
          <img
            className={'w-full h-full object-cover'}
            src={cover}
          />
        </div>
      )}
      <div className={'flex flex-col gap-2 py-2 px-3'}>
        {showFields.map((field, index) => {
          return <CardField index={index} key={field.fieldId} rowId={rowId} fieldId={field.fieldId} />;
        })}
      </div>

    </div>
  );
});

export default Card;
