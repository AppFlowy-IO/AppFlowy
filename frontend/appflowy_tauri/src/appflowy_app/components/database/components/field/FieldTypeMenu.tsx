import { Divider, Menu, MenuItem, MenuProps } from '@mui/material';
import { FC, useMemo } from 'react';
import { FieldType } from '@/services/backend';
import { FieldTypeText, FieldTypeSvg } from '$app/components/database/components/field/index';
import { Field } from '$app/components/database/application';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';

const FieldTypeGroup = [
  {
    name: 'Basic',
    types: [
      FieldType.RichText,
      FieldType.Number,
      FieldType.SingleSelect,
      FieldType.MultiSelect,
      FieldType.DateTime,
      FieldType.Checkbox,
      FieldType.Checklist,
      FieldType.URL,
    ],
  },
  {
    name: 'Advanced',
    types: [FieldType.LastEditedTime],
  },
];

export const FieldTypeMenu: FC<
  MenuProps & {
    field: Field;
    onClickItem?: (type: FieldType) => void;
  }
> = ({ field, onClickItem, ...props }) => {
  const PopoverClasses = useMemo(
    () => ({
      ...props.PopoverClasses,
      paper: ['w-56', props.PopoverClasses?.paper].join(' '),
    }),
    [props.PopoverClasses]
  );

  return (
    <Menu {...props} PopoverClasses={PopoverClasses}>
      {FieldTypeGroup.map((group, index) => [
        <MenuItem key={group.name} dense disabled>
          {group.name}
        </MenuItem>,
        group.types.map((type) => (
          <MenuItem onClick={() => onClickItem?.(type)} key={type} dense className={'flex justify-between'}>
            <FieldTypeSvg className='mr-2 text-base' type={type} />
            <span className='flex-1 font-medium'>
              <FieldTypeText type={type} />
            </span>
            {type === field.type && <SelectCheckSvg />}
          </MenuItem>
        )),
        index < FieldTypeGroup.length - 1 && <Divider key={`Divider-${group.name}`} />,
      ])}
    </Menu>
  );
};
