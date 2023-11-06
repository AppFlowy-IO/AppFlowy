import { DatabaseLayoutPB } from '@/services/backend';
import { FC } from 'react';
import { useDatabase } from './Database.hooks';
import { Grid } from './grid';
import { Board } from './board';
import { Calendar } from './calendar';

const ViewMap: Record<DatabaseLayoutPB, FC | null> = {
  [DatabaseLayoutPB.Grid]: Grid,
  [DatabaseLayoutPB.Board]: Board,
  [DatabaseLayoutPB.Calendar]: Calendar,
};

export const DatabaseView: FC = () => {
  const { layoutType } = useDatabase();
  const View = ViewMap[layoutType];

  return View && <View />;
};
