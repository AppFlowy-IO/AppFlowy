import { useFieldsSelector } from '@/application/database-yjs';
import CardField from '@/components/database/components/field/CardField';
import React, { memo, useEffect, useMemo } from 'react';

export interface CardProps {
  groupFieldId: string;
  rowId: string;
  onResize?: (height: number) => void;
  isDragging?: boolean;
}

export const Card = memo(({ groupFieldId, rowId, onResize, isDragging }: CardProps) => {
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

  // const navigateToRow = useNavigateToRow();

  return (
    <div
      onClick={() => {
        // navigateToRow?.(rowId);
      }}
      ref={ref}
      style={{
        minHeight: '38px',
      }}
      className="relative shadow-sm flex flex-col gap-2 overflow-hidden rounded-[8px] border border-line-divider p-3 text-xs"
    >
      {showFields.map((field, index) => {
        return <CardField index={index} key={field.fieldId} rowId={rowId} fieldId={field.fieldId} />;
      })}
    </div>
  );
});

export default Card;
