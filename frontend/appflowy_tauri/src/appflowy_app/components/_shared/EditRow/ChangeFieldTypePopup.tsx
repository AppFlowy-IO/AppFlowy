import { FieldType } from '@/services/backend';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { useEffect, useRef, useState } from 'react';

const typesOrder: FieldType[] = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.DateTime,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.Checkbox,
  FieldType.URL,
  FieldType.Checklist,
];

export const ChangeFieldTypePopup = ({ top, right, onClick }: { top: number; right: number; onClick: () => void }) => {
  const ref = useRef<HTMLDivElement>(null);
  const [adjustedTop, setAdjustedTop] = useState(0);

  useEffect(() => {
    if (!ref.current) return;
    const { height } = ref.current.getBoundingClientRect();
    if (top + height > window.innerHeight) {
      setAdjustedTop(window.innerHeight - height);
    } else {
      setAdjustedTop(top);
    }
  }, [ref, window, top, right]);

  return (
    <div
      ref={ref}
      className={'fixed z-20 rounded-lg bg-white p-2 shadow-md'}
      style={{ top: `${adjustedTop}px`, left: `${right + 30}px` }}
    >
      <div className={'flex flex-col'}>
        {typesOrder.map((t, i) => (
          <button
            onClick={() => onClick()}
            key={i}
            className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-main-secondary'}
          >
            <i className={'h-5 w-5'}>
              <FieldTypeIcon fieldType={t}></FieldTypeIcon>
            </i>
            <span>
              <FieldTypeName fieldType={t}></FieldTypeName>
            </span>
          </button>
        ))}
      </div>
    </div>
  );
};
