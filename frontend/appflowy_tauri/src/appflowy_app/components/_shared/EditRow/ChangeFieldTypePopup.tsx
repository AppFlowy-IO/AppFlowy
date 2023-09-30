import { FieldType } from '@/services/backend';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { Popover } from '@mui/material';

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
  open,
  anchorEl,
  onClick,
  onOutsideClick,
}: {
  open: boolean;
  anchorEl: HTMLDivElement | null;
  onClick: (newType: FieldType) => void;
  onOutsideClick: () => void;
}) => {
  return (
    <Popover
      open={open}
      anchorEl={anchorEl}
      anchorOrigin={{
        vertical: 'top',
        horizontal: 'right',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
      onClose={onOutsideClick}
    >
      <div className={'flex flex-col p-2 text-xs'}>
        {typesOrder.map((t, i) => (
          <button
            onClick={() => onClick(t)}
            key={i}
            className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-fill-list-hover'}
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
    </Popover>
  );
};
