import { ColumnDef, getCoreRowModel, useReactTable } from '@tanstack/react-table';
import { useEffect, useState } from 'react';
import { gridActions } from '../../../stores/reducers/grid/slice';
import { useAppDispatch, useAppSelector } from '../../../stores/store';
import { GridTableCell } from '../GridTableCell/GridTableCell';

export const useGridTableHooks = function () {
  const dispatch = useAppDispatch();

  const grid = useAppSelector((state) => state.grid);

  // find the field with an id of fieldId
  const findField = (fieldId: string) => {
    return grid.fields.find((field) => field.fieldId === fieldId)?.name;
  };

  const defaultData = grid.rows.map((row) => {
    const values: any = {
      rowId: row.rowId,
    };
    row.values.forEach((cell) => {
      values[findField(cell.fieldId)!] = cell.value;
    });
    return values;
  });

  const defaultColumns: ColumnDef<any>[] = grid.fields.map((field) => {
    return {
      header: field.name,
      id: field.fieldId,
      meta: field.fieldType,
      accessorKey: field.name,
      fieldType: field.fieldType,
      cell(props) {
        return <GridTableCell props={props} />;
      },
    };
  });

  const [data, setData] = useState(() => [...defaultData]);
  const [columns, setColumns] = useState<typeof defaultColumns>(() => [...defaultColumns]);

  useEffect(() => {
    setData(
      grid.rows.map((row) => {
        const values: any = {
          rowId: row.rowId,
        };
        row.values.forEach((cell) => {
          values[findField(cell.fieldId)!] = cell.value;
        });
        return values;
      })
    );
  }, [grid.rows]);

  useEffect(() => {
    setColumns(
      grid.fields.map((field) => {
        return {
          header: field.name,
          // 100% divided by the number of cols
          size: field.size,
          maxSize: Number.MAX_SAFE_INTEGER,
          minSize: 100,

          id: field.fieldId,
          meta: field.fieldType,
          accessorKey: field.name,
          fieldType: field.fieldType,
          cell(props) {
            return <GridTableCell props={props} />;
          },
        };
      })
    );
  }, [grid.fields]);

  const updateColumnSize = (fieldIndex: number, size: number) => {
    dispatch(gridActions.updateColumnSize({ fieldIndex, size }));
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

    Object.keys(sizes).forEach((key) => {
      const size = sizes[key];
      updateColumnSize(Number(key) - 1, size);
    });
  }, [table.getState().columnSizing]);

  return {
    fields: grid.fields,
    rows: grid.rows,

    updateColumnSize,
    data,
    columns,

    table,
  };
};
