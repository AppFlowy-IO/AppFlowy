import { OnDragEndResponder } from 'react-beautiful-dnd';

export const useGridTableRows = () => {
  const onRowsDragEnd: OnDragEndResponder = (result) => {
    console.log({ result });
  };

  return {
    onRowsDragEnd,
  };
};
