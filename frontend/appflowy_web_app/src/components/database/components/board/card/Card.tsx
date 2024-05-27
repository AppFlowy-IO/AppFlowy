import { useFieldsSelector, useNavigateToRow } from '@/application/database-yjs';
import OpenAction from '@/components/database/components/database-row/OpenAction';
import CardField from '@/components/database/components/field/CardField';
import { getPlatform } from '@/utils/platform';
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

  const [isHovering, setIsHovering] = React.useState(false);
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

  const isMobile = useMemo(() => {
    return getPlatform().isMobile;
  }, []);

  const navigateToRow = useNavigateToRow();

  return (
    <div
      onClick={() => {
        if (isMobile) {
          navigateToRow?.(rowId);
        }
      }}
      ref={ref}
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => setIsHovering(false)}
      style={{
        minHeight: '38px',
      }}
      className='relative flex cursor-pointer flex-col rounded-lg border border-line-divider p-3 text-xs shadow-sm hover:bg-fill-list-active hover:shadow'
    >
      {showFields.map((field, index) => {
        return <CardField index={index} key={field.fieldId} rowId={rowId} fieldId={field.fieldId} />;
      })}
      <div className={`absolute top-1.5 right-1.5  ${isHovering ? 'block' : 'hidden'}`}>
        <OpenAction rowId={rowId} />
      </div>
    </div>
  );
}

export default Card;
