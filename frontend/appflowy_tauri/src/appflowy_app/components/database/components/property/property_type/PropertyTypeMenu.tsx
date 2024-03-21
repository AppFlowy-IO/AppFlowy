import { Menu, MenuProps } from '@mui/material';
import { FC, useCallback, useMemo } from 'react';
import { FieldType } from '@/services/backend';
import { PropertyTypeText, ProppertyTypeSvg } from '$app/components/database/components/property';
import { Field } from '$app/application/database';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import Typography from '@mui/material/Typography';

export const PropertyTypeMenu: FC<
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

  const renderGroupContent = useCallback((title: string) => {
    return (
      <Typography variant='subtitle2' className='px-2'>
        {title}
      </Typography>
    );
  }, []);

  const renderContent = useCallback(
    (type: FieldType) => {
      return (
        <>
          <ProppertyTypeSvg className='mr-2 text-base' type={type} />
          <span className='flex-1 font-medium'>
            <PropertyTypeText type={type} />
          </span>
          {type === field.type && <SelectCheckSvg className={'text-content-blue-400'} />}
        </>
      );
    },
    [field.type]
  );

  const options: KeyboardNavigationOption<FieldType>[] = useMemo(() => {
    return [
      {
        key: 100,
        content: renderGroupContent('Basic'),
        children: [
          {
            key: FieldType.RichText,
            content: renderContent(FieldType.RichText),
          },
          {
            key: FieldType.Number,
            content: renderContent(FieldType.Number),
          },
          {
            key: FieldType.SingleSelect,
            content: renderContent(FieldType.SingleSelect),
          },
          {
            key: FieldType.MultiSelect,
            content: renderContent(FieldType.MultiSelect),
          },
          {
            key: FieldType.DateTime,
            content: renderContent(FieldType.DateTime),
          },
          {
            key: FieldType.Checkbox,
            content: renderContent(FieldType.Checkbox),
          },
          {
            key: FieldType.Checklist,
            content: renderContent(FieldType.Checklist),
          },
          {
            key: FieldType.URL,
            content: renderContent(FieldType.URL),
          },
        ],
      },
      {
        key: 101,
        content: <hr className={'h-[1px] w-full bg-line-divider opacity-40'} />,
        children: [],
      },
      {
        key: 102,
        content: renderGroupContent('Advanced'),
        children: [
          {
            key: FieldType.LastEditedTime,
            content: renderContent(FieldType.LastEditedTime),
          },
          {
            key: FieldType.CreatedTime,
            content: renderContent(FieldType.CreatedTime),
          },
        ],
      },
    ];
  }, [renderContent, renderGroupContent]);

  return (
    <Menu {...props} PopoverClasses={PopoverClasses}>
      <KeyboardNavigation
        onEscape={() => props?.onClose?.({}, 'escapeKeyDown')}
        options={options}
        disableFocus={true}
        onConfirm={onClickItem}
      />
    </Menu>
  );
};
