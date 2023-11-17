import { Divider, Menu, MenuItem, MenuProps } from '@mui/material';
import { FC, useMemo } from 'react';
import { FieldType } from '@/services/backend';
import { FieldTypeText, FieldTypeSvg } from '$app/components/database/components/field/index';

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
    ],
  },
  {
    name: 'Advanced',
    types: [FieldType.LastEditedTime],
  },
];

export const FieldTypeMenu: FC<MenuProps> = (props) => {
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
          <MenuItem key={type} dense>
            <FieldTypeSvg className='mr-2 text-base' type={type} />
            <span className='font-medium'>
              <FieldTypeText type={type} />
            </span>
          </MenuItem>
        )),
        index < FieldTypeGroup.length - 1 && <Divider key={`Divider-${group.name}`} />,
      ])}
    </Menu>
  );
};
