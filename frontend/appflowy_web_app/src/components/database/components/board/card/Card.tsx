import { useFieldsSelector } from '@/application/database-yjs';
import CardField from '@/components/database/components/field/CardField';
import React, { useEffect, useMemo } from 'react';

export interface CardProps {
  groupFieldId: string;
  rowId: string;
  onResize?: (height: number) => void;
  isDragging?: boolean;
}

export function Card({ groupFieldId, rowId, onResize, isDragging }: CardProps) {
  const fields = useFieldsSelector();
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

  return (
    <div
      ref={ref}
      style={{
        minHeight: '38px',
      }}
      className='flex cursor-pointer flex-col rounded-lg border border-line-divider p-3 shadow-sm hover:bg-fill-list-active hover:shadow'
    >
      {showFields.map((field, index) => {
        return <CardField index={index} key={field.fieldId} rowId={rowId} fieldId={field.fieldId} />;
      })}
    </div>
  );
}

export default Card;
