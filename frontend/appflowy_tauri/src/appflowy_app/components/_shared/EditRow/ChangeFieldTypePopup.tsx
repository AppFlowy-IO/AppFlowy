import { FieldType } from '@/services/backend';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { PopupWindow } from '$app/components/_shared/PopupWindow';

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

export const ChangeFieldTypePopup = ({
  top,
  left,
  onClick,
  onOutsideClick,
}: {
  top: number;
  left: number;
  onClick: (newType: FieldType) => void;
  onOutsideClick: () => void;
}) => {
  return (
    <PopupWindow className={'p-2 text-xs'} onOutsideClick={onOutsideClick} left={left} top={top}>
      <div className={'flex flex-col'}>
        {typesOrder.map((t, i) => (
          <button
            onClick={() => onClick(t)}
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
    </PopupWindow>
  );
};
