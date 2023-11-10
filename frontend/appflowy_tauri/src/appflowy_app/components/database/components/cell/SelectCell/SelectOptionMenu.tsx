import { FC } from 'react';
import { t } from 'i18next';
import {
  Divider,
  ListSubheader,
  Menu,
  MenuItem,
  MenuProps,
  OutlinedInput,
} from '@mui/material';
import { SelectOptionColorPB } from '@/services/backend';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';
import { SelectOption } from '../../../application';
import { SelectOptionColorMap, SelectOptionColorTextMap } from './constants';

interface SelectOptionMenuProps {
  option: SelectOption;
  open: boolean;
  MenuProps?: Partial<MenuProps>;
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

export const SelectOptionMenu: FC<SelectOptionMenuProps> = ({
  open,
  option,
  MenuProps: menuProps,
}) => {
  return (
    <Menu
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
      open={open}
    >
      <ListSubheader className="leading-tight">
        <OutlinedInput size="small" />
      </ListSubheader>
      <MenuItem>
        <DeleteSvg className="mr-2 text-base" />
        {t('grid.selectOption.deleteTag')}
      </MenuItem>
      <Divider />
      <MenuItem disabled>{t('grid.selectOption.colorPanelTitle')}</MenuItem>
      {Colors.map(color => (
        <MenuItem key={color} value={color}>
          <span className={`inline-flex w-4 h-4 mr-2 rounded-full ${SelectOptionColorMap[color]}`} />
          <span className="flex-1">
            {t(`grid.selectOption.${SelectOptionColorTextMap[color]}`)}
          </span>
          {option.color === color && (
            <SelectCheckSvg />
          )}
        </MenuItem>
      ))}
    </Menu>
  );
};
