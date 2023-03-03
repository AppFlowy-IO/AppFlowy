import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { boardActions } from '../../stores/reducers/board/slice';
import { IDatabase, IDatabaseRow, ISelectOption } from '../../stores/reducers/database/slice';

export const useBoard = () => {
  const dispatch = useAppDispatch();
  const groupingFieldId = useAppSelector((state) => state.board);
  const database = useAppSelector((state) => state.database);
  const [title, setTitle] = useState('');
  const [boardColumns, setBoardColumns] =
    useState<(ISelectOption & { rows: (IDatabaseRow & { isGhost: boolean })[] })[]>();
  const [movingRowId, setMovingRowId] = useState<string | undefined>(undefined);
  const [ghostLocation, setGhostLocation] = useState<{ column: number; row: number }>({ column: 0, row: 0 });

  useEffect(() => {
    setTitle(database.title);
    if (database.fields[groupingFieldId]) {
      setBoardColumns(
        database.fields[groupingFieldId].fieldOptions.selectOptions?.map((groupFieldItem) => {
        /*  const rows = database.rows
            .filter((row) => row.cells[groupingFieldId].data?.some((so) => so === groupFieldItem.selectOptionId))
            .map((row) => ({
              ...row,
              isGhost: false,
            }));*/
          return {
            ...groupFieldItem,
            rows: [],
          };
        }) || []
      );
    }
  }, [database, groupingFieldId]);

  const changeGroupingField = (fieldId: string) => {
    dispatch(
      boardActions.setGroupingFieldId({
        fieldId,
      })
    );
  };

  const onGhostItemMove = (columnIndex: number, rowIndex: number) => {
    setGhostLocation({ column: columnIndex, row: rowIndex });
  };

  const startMove = (rowId: string) => {
    setMovingRowId(rowId);
  };

  const endMove = () => {
    setMovingRowId(undefined);
  };

  return {
    title,
    boardColumns,
    groupingFieldId,
    changeGroupingField,
    startMove,
    endMove,
    onGhostItemMove,
    movingRowId,
    ghostLocation,
  };
};
