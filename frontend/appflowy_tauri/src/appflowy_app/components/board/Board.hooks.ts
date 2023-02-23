import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../stores/store';
import { boardActions } from '../../stores/reducers/board/slice';
import { ICellData, IDatabase, IDatabaseRow, ISelectOption } from '../../stores/reducers/database/slice';

export const useBoard = (databaseId: string) => {
  const dispatch = useAppDispatch();
  const boardStore = useAppSelector((state) => state.board);
  const databaseStore = useAppSelector((state) => state.database);
  const [database, setDatabase] = useState<IDatabase>();
  const [groupingFieldId, setGroupingFieldId] = useState('');
  const [title, setTitle] = useState('');
  const [boardColumns, setBoardColumns] =
    useState<(ISelectOption & { rows: (IDatabaseRow & { isGhost: boolean })[] })[]>();
  const [movingRowId, setMovingRowId] = useState<string | undefined>(undefined);
  const [ghostLocation, setGhostLocation] = useState<{ column: number; row: number }>({ column: 0, row: 0 });

  useEffect(() => {
    if (!databaseId?.length || !databaseStore) return;
    setDatabase(databaseStore[databaseId]);
  }, [databaseStore, databaseId]);

  useEffect(() => {
    if (!databaseId?.length || !boardStore) return;
    setGroupingFieldId(boardStore[databaseId]);
  }, [boardStore, databaseId]);

  useEffect(() => {
    if (!database) return;
    setTitle(database.title);
    setBoardColumns(
      database.fields[groupingFieldId].fieldOptions.selectOptions?.map((groupFieldItem) => {
        const rows = database.rows
          .filter((row) => row.cells[groupingFieldId].optionIds?.some((so) => so === groupFieldItem.selectOptionId))
          .map((row) => ({
            ...row,
            isGhost: false,
          }));
        return {
          ...groupFieldItem,
          rows: rows,
        };
      }) || []
    );
  }, [database, groupingFieldId]);

  const changeGroupingField = (fieldId: string) => {
    dispatch(
      boardActions.setGroupingFieldId({
        databaseId,
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
