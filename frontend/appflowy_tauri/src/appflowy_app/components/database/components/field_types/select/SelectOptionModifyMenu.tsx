import { FC, useMemo, useRef, useState } from 'react';
import { Divider, ListSubheader, MenuItem, MenuList, MenuProps, OutlinedInput } from '@mui/material';
import { SelectOptionColorPB } from '@/services/backend';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';
import { SelectOption } from '$app/application/database';
import { SelectOptionColorMap, SelectOptionColorTextMap } from './constants';
import Button from '@mui/material/Button';
import {
  deleteSelectOption,
  insertOrUpdateSelectOption,
} from '$app/application/database/field/select_option/select_option_service';
import { useViewId } from '$app/hooks';
import Popover from '@mui/material/Popover';
import debounce from 'lodash-es/debounce';
import { useTranslation } from 'react-i18next';

interface SelectOptionMenuProps {
  fieldId: string;
  option: SelectOption;
  MenuProps: MenuProps;
}

const Colors = [
  SelectOptionColorPB.Purple,
  SelectOptionColorPB.Pink,
  SelectOptionColorPB.LightPink,
  SelectOptionColorPB.Orange,
  SelectOptionColorPB.Yellow,
  SelectOptionColorPB.Lime,
  SelectOptionColorPB.Green,
  SelectOptionColorPB.Aqua,
  SelectOptionColorPB.Blue,
];

export const SelectOptionModifyMenu: FC<SelectOptionMenuProps> = ({ fieldId, option, MenuProps: menuProps }) => {
  const { t } = useTranslation();
  const [tagName, setTagName] = useState(option.name);
  const viewId = useViewId();
  const inputRef = useRef<HTMLInputElement>(null);
  const updateColor = async (color: SelectOptionColorPB) => {
    await insertOrUpdateSelectOption(viewId, fieldId, [
      {
        ...option,
        color,
      },
    ]);
  };

  const updateName = useMemo(() => {
    return debounce(async (tagName) => {
      if (tagName === option.name) return;

      await insertOrUpdateSelectOption(viewId, fieldId, [
        {
          ...option,
          name: tagName,
        },
      ]);
    }, 500);
  }, [option, viewId, fieldId]);

  const onClose = () => {
    menuProps.onClose?.({}, 'backdropClick');
  };

  const deleteOption = async () => {
    await deleteSelectOption(viewId, fieldId, [option]);
    onClose();
  };

  return (
    <Popover
      keepMounted={false}
      classes={{
        paper: 'w-52',
      }}
      anchorOrigin={{
        vertical: 'top',
        horizontal: 'right',
      }}
      transformOrigin={{
        vertical: 'center',
        horizontal: -32,
      }}
      {...menuProps}
      onClick={(e) => {
        e.stopPropagation();
      }}
      onClose={onClose}
      onMouseDown={(e) => {
        const isInput = inputRef.current?.contains(e.target as Node);

        if (isInput) return;
        e.preventDefault();
        e.stopPropagation();
      }}
    >
      <ListSubheader className='my-2 leading-tight'>
        <OutlinedInput
          inputRef={inputRef}
          spellCheck={false}
          autoCorrect={'off'}
          autoCapitalize={'off'}
          value={tagName}
          onChange={(e) => {
            setTagName(e.target.value);
            void updateName(e.target.value);
          }}
          onKeyDown={(e) => {
            if (e.key === 'Escape') {
              e.preventDefault();
              e.stopPropagation();
              void updateName(tagName);
              onClose();
            }
          }}
          onClick={(e) => {
            e.stopPropagation();
          }}
          onMouseDown={(e) => {
            e.stopPropagation();
          }}
          autoFocus={true}
          placeholder={t('grid.selectOption.tagName')}
          size='small'
        />
      </ListSubheader>
      <div className={'mb-2 px-3'}>
        <Button
          className={'flex w-full justify-start'}
          onClick={deleteOption}
          color={'inherit'}
          startIcon={<DeleteSvg />}
        >
          {t('grid.selectOption.deleteTag')}
        </Button>
      </div>

      <Divider />
      <MenuItem disabled>{t('grid.selectOption.colorPanelTitle')}</MenuItem>
      <MenuList className={'max-h-[300px] overflow-y-auto overflow-x-hidden px-2'}>
        {Colors.map((color) => (
          <MenuItem
            onMouseDown={(e) => {
              e.preventDefault();
              e.stopPropagation();
            }}
            onClick={(e) => {
              e.preventDefault();
              void updateColor(color);
            }}
            key={color}
            value={color}
            className={'px-1.5'}
          >
            <span className={`mr-2 inline-flex h-4 w-4 rounded-full ${SelectOptionColorMap[color]}`} />
            <span className='flex-1'>{t(`grid.selectOption.${SelectOptionColorTextMap[color]}`)}</span>
            {option.color === color && <SelectCheckSvg className={'text-content-blue-400'} />}
          </MenuItem>
        ))}
      </MenuList>
    </Popover>
  );
};
