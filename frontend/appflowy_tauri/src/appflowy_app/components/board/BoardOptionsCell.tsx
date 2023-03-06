import { SelectOptionCellDataPB, SelectOptionColorPB } from '../../../services/backend';

export const BoardOptionsCell = ({ value }: { value: SelectOptionCellDataPB | undefined }) => {
  return <>{value?.select_options?.map((option, index) => <div key={index}>{option?.name || ''}</div>) || ''}</>;
};
