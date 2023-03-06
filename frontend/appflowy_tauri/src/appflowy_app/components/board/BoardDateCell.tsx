import { DateCellDataPB } from '../../../services/backend';

export const BoardDateCell = ({ value }: { value: DateCellDataPB | undefined }) => {
  return <div>{value?.date || ''}</div>;
};
