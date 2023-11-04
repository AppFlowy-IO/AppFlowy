import { DatabaseLayoutPB } from '@/services/backend';
import { FC } from 'react';
import { useDatabase } from './Database.hooks';
import { Grid } from './grid';
import { Board } from './board';
import { Calendar } from './calendar';

export const DatabaseView: FC = () => {
  const { layoutType } = useDatabase();

  switch (layoutType) {
    case DatabaseLayoutPB.Grid:
      return <Grid />;
    case DatabaseLayoutPB.Board:
      return <Board />;
    case DatabaseLayoutPB.Calendar:
      return <Calendar />;
    default:
      return null;
  }
};
