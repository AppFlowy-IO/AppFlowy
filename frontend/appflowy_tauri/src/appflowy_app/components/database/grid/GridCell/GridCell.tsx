import { FC } from 'react';
import { Cell, CellProps } from '../../components';

export const GridCell: FC<CellProps> = (props) => {
  return <Cell {...props} />;
};
