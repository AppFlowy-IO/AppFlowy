import { ColumnDef, getCoreRowModel, useReactTable } from '@tanstack/react-table';
import { useEffect, useState } from 'react';
import { databaseActions } from '../../../stores/reducers/database/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { GridTableCell } from '../GridTableCell/GridTableCell';

export const useGridTableHooks = function () {
  const dispatch = useAppDispatch();

  const database = useAppSelector((state) => state.database);

  const d = database.rows.map((row) => {
    return {
      rowId: row.rowId,
      ...row.cells,
    };
  });

  const defaultColumns: ColumnDef<any>[] = database.columns.map((column) => {
    return {
      header: column.fieldId,
      id: column.fieldId,
      accessorKey: column.fieldId,

      cell(props) {
        return <GridTableCell props={props} />;
      },
    };
  });

  const [data, setData] = useState(() => [...d]);
  const [columns, setColumns] = useState<typeof defaultColumns>(() => [...defaultColumns]);

  useEffect(() => {
    setData([...d]);
  }, [database.rows]);

  useEffect(() => {
    setColumns(
      database.columns.map((column) => {
        return {
          header: column.fieldId,
          id: column.fieldId,
          accessorKey: column.fieldId,
          size: column.size,
          maxSize: Number.MAX_SAFE_INTEGER,
          minSize: 100,

          cell(props) {
            return <GridTableCell props={props} />;
          },
        };
      })
    );
  }, [database.columns]);

  const updateColumnSize = (fieldId: string, size: number) => {
    console.log({ fieldId, size });
    dispatch(databaseActions.updateColumnSize({ fieldId, size }));
  };

  const table = useReactTable({
    data,
    columns,
    columnResizeMode: 'onChange',
    getCoreRowModel: getCoreRowModel(),
    debugTable: true,
    debugHeaders: true,
    debugColumns: true,
  });

  useEffect(() => {
    const sizes = table.getState().columnSizing;

    console.log(sizes);

    Object.keys(sizes).forEach((key) => {
      const size = sizes[key];
      updateColumnSize(key, size);
    });
  }, [table.getState().columnSizing]);

  return {
    fields: database.columns,
    rows: database.rows,

    updateColumnSize,
    data,
    columns,

    table,
  };
};
