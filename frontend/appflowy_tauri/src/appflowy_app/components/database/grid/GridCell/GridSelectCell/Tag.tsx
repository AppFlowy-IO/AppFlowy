import { FC } from 'react';
import { Chip, ChipProps } from '@mui/material';
import { SelectOptionColorPB } from '@/services/backend';
import { SelectOptionColorMap } from './constants';

export interface TagProps extends Omit<ChipProps, 'color'> {
  color?: SelectOptionColorPB | ChipProps['color'];
}

export const Tag: FC<TagProps> = ({ color, classes, ...props }) => {

  return (
    <Chip
      {...props}
      color={typeof color === 'number' ? undefined : color}
      classes={{
        ...classes,
        root: [
          'rounded-md',
          typeof color === 'number' ? SelectOptionColorMap[color] : '',
          classes?.root,
        ].join(' '),
        label: ['font-medium text-xs', classes?.label].join(' '),
      }}
    />
  )
}
