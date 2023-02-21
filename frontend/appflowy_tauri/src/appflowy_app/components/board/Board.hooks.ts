import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { boardActions } from '../../stores/reducers/board/slice';

export const useBoard = (databaseId: string) => {
  const dispatch = useAppDispatch();
  const boardStore = useAppSelector((state) => state.board);

  const [groupingFieldId, setGroupingFieldId] = useState('');
  useEffect(() => {
    setGroupingFieldId(boardStore[databaseId]);
  }, [boardStore]);

  const changeGroupingField = (fieldId: string) => {
    dispatch(
      boardActions.setGroupingFieldId({
        databaseId,
        fieldId,
      })
    );
  };

  return {
    groupingFieldId,
    changeGroupingField,
  };
};
