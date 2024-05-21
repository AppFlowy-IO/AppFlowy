import { FieldId, SortId, YDatabaseField, YjsDatabaseKey } from '@/application/collab.type';
import { MIN_COLUMN_WIDTH } from '@/application/database-yjs/const';
import {
  DatabaseContext,
  useDatabase,
  useDatabaseFields,
  useDatabaseView,
  useRowMeta,
  useRows,
  useViewId,
} from '@/application/database-yjs/context';
import { filterBy, parseFilter } from '@/application/database-yjs/filter';
import { groupByField } from '@/application/database-yjs/group';
import { sortBy } from '@/application/database-yjs/sort';
import { useViewsIdSelector } from '@/application/folder-yjs';
import { parseYDatabaseCellToCell } from '@/components/database/components/cell/cell.parse';
import debounce from 'lodash-es/debounce';
import { useContext, useEffect, useMemo, useState } from 'react';
import { FieldType, FieldVisibility, Filter, SortCondition } from './database.type';

export interface Column {
  fieldId: string;
  width: number;
  visibility: FieldVisibility;
  wrap?: boolean;
}

export interface Row {
  id: string;
  height: number;
}

const defaultVisible = [FieldVisibility.AlwaysShown, FieldVisibility.HideWhenEmpty];

export function useDatabaseViewsSelector() {
  const database = useDatabase();
  const { viewsId: visibleViewsId } = useViewsIdSelector();
  const views = database?.get(YjsDatabaseKey.views);
  const [viewIds, setViewIds] = useState<string[]>([]);
  const childViews = useMemo(() => {
    return viewIds.map((viewId) => views?.get(viewId));
  }, [viewIds, views]);

  useEffect(() => {
    if (!views) return;

    const observerEvent = () => {
      setViewIds(Array.from(views.keys()).filter((id) => visibleViewsId.includes(id)));
    };

    observerEvent();
    views.observe(observerEvent);

    return () => {
      views.unobserve(observerEvent);
    };
  }, [visibleViewsId, views]);

  return {
    childViews,
    viewIds,
  };
}

export function useFieldsSelector(visibilitys: FieldVisibility[] = defaultVisible) {
  const viewId = useViewId();
  const database = useDatabase();
  const [columns, setColumns] = useState<Column[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const fields = database?.get(YjsDatabaseKey.fields);
    const fieldsOrder = view?.get(YjsDatabaseKey.field_orders);
    const fieldSettings = view?.get(YjsDatabaseKey.field_settings);
    const getColumns = () => {
      if (!fields || !fieldsOrder || !fieldSettings) return [];
      const fieldIds = fieldsOrder.toJSON().map((item) => item.id) as string[];

      return fieldIds
        .map((fieldId) => {
          const setting = fieldSettings.get(fieldId);

          return {
            fieldId,
            width: parseInt(setting?.get(YjsDatabaseKey.width)) || MIN_COLUMN_WIDTH,
            visibility: Number(
              setting?.get(YjsDatabaseKey.visibility) || FieldVisibility.AlwaysShown
            ) as FieldVisibility,
            wrap: setting?.get(YjsDatabaseKey.wrap),
          };
        })
        .filter((column) => {
          return visibilitys.includes(column.visibility);
        });
    };

    const observerEvent = () => setColumns(getColumns());

    setColumns(getColumns());

    fieldsOrder?.observe(observerEvent);
    fieldSettings?.observe(observerEvent);

    return () => {
      fieldsOrder?.unobserve(observerEvent);
      fieldSettings?.unobserve(observerEvent);
    };
  }, [database, viewId, visibilitys]);

  return columns;
}

export function useRowsSelector() {
  const rowOrders = useRows();

  return useMemo(() => rowOrders ?? [], [rowOrders]);
}

export function useFieldSelector(fieldId: string) {
  const database = useDatabase();
  const [field, setField] = useState<YDatabaseField | null>(null);
  const [clock, setClock] = useState<number>(0);

  useEffect(() => {
    if (!database) return;

    const field = database.get(YjsDatabaseKey.fields)?.get(fieldId);

    setField(field || null);
    const observerEvent = () => setClock((prev) => prev + 1);

    field?.observe(observerEvent);

    return () => {
      field?.unobserve(observerEvent);
    };
  }, [database, fieldId]);

  return {
    field,
    clock,
  };
}

export function useFiltersSelector() {
  const database = useDatabase();
  const viewId = useViewId();
  const [filters, setFilters] = useState<string[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const filterOrders = view?.get(YjsDatabaseKey.filters);

    if (!filterOrders) return;

    const getFilters = () => {
      return filterOrders.toJSON().map((item) => item.id);
    };

    const observerEvent = () => setFilters(getFilters());

    setFilters(getFilters());

    filterOrders.observe(observerEvent);

    return () => {
      filterOrders.unobserve(observerEvent);
    };
  }, [database, viewId]);

  return filters;
}

export function useFilterSelector(filterId: string) {
  const database = useDatabase();
  const viewId = useViewId();
  const fields = database?.get(YjsDatabaseKey.fields);
  const [filterValue, setFilterValue] = useState<Filter | null>(null);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const filter = view
      ?.get(YjsDatabaseKey.filters)
      .toArray()
      .find((filter) => filter.get(YjsDatabaseKey.id) === filterId);
    const field = fields?.get(filter?.get(YjsDatabaseKey.field_id) as FieldId);

    const observerEvent = () => {
      if (!filter || !field) return;
      const fieldType = Number(field.get(YjsDatabaseKey.type)) as FieldType;

      setFilterValue(parseFilter(fieldType, filter));
    };

    observerEvent();
    field?.observe(observerEvent);
    filter?.observe(observerEvent);
    return () => {
      field?.unobserve(observerEvent);
      filter?.unobserve(observerEvent);
    };
  }, [fields, viewId, filterId, database]);
  return filterValue;
}

export function useSortsSelector() {
  const database = useDatabase();
  const viewId = useViewId();
  const [sorts, setSorts] = useState<string[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const sortOrders = view?.get(YjsDatabaseKey.sorts);

    if (!sortOrders) return;

    const getSorts = () => {
      return sortOrders.toJSON().map((item) => item.id);
    };

    const observerEvent = () => setSorts(getSorts());

    setSorts(getSorts());

    sortOrders.observe(observerEvent);

    return () => {
      sortOrders.unobserve(observerEvent);
    };
  }, [database, viewId]);

  return sorts;
}

export interface Sort {
  fieldId: FieldId;
  condition: SortCondition;
  id: SortId;
}

export function useSortSelector(sortId: SortId) {
  const database = useDatabase();
  const viewId = useViewId();
  const [sortValue, setSortValue] = useState<Sort | null>(null);
  const views = database?.get(YjsDatabaseKey.views);

  useEffect(() => {
    if (!viewId) return;
    const view = views?.get(viewId);
    const sort = view
      ?.get(YjsDatabaseKey.sorts)
      .toArray()
      .find((sort) => sort.get(YjsDatabaseKey.id) === sortId);

    const observerEvent = () => {
      setSortValue({
        fieldId: sort?.get(YjsDatabaseKey.field_id) as FieldId,
        condition: Number(sort?.get(YjsDatabaseKey.condition)),
        id: sort?.get(YjsDatabaseKey.id) as SortId,
      });
    };

    observerEvent();
    sort?.observe(observerEvent);

    return () => {
      sort?.unobserve(observerEvent);
    };
  }, [viewId, sortId, views]);

  return sortValue;
}

export function useGroupsSelector() {
  const database = useDatabase();
  const viewId = useViewId();
  const [groups, setGroups] = useState<string[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const groupOrders = view?.get(YjsDatabaseKey.groups);

    if (!groupOrders) return;

    const getGroups = () => {
      return groupOrders.toJSON().map((item) => item.id);
    };

    const observerEvent = () => setGroups(getGroups());

    setGroups(getGroups());

    groupOrders.observe(observerEvent);

    return () => {
      groupOrders.unobserve(observerEvent);
    };
  }, [database, viewId]);

  return groups;
}

export interface GroupColumn {
  id: string;
  visible: boolean;
}

export function useGroup(groupId: string) {
  const database = useDatabase();
  const viewId = useViewId() as string;
  const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
  const group = view
    ?.get(YjsDatabaseKey.groups)
    ?.toArray()
    .find((group) => group.get(YjsDatabaseKey.id) === groupId);
  const groupColumns = group?.get(YjsDatabaseKey.groups);
  const [fieldId, setFieldId] = useState<string | null>(null);
  const [columns, setColumns] = useState<GroupColumn[]>([]);

  useEffect(() => {
    if (!viewId) return;

    const observerEvent = () => {
      setFieldId(group?.get(YjsDatabaseKey.field_id) as string);
    };

    observerEvent();
    group?.observe(observerEvent);

    const observerColumns = () => {
      if (!groupColumns) return;
      setColumns(groupColumns.toJSON());
    };

    observerColumns();
    groupColumns?.observe(observerColumns);

    return () => {
      group?.unobserve(observerEvent);
      groupColumns?.unobserve(observerColumns);
    };
  }, [database, viewId, groupId, group, groupColumns]);

  return {
    columns,
    fieldId,
  };
}

export function useRowsByGroup(groupId: string) {
  const { columns, fieldId } = useGroup(groupId);
  const rows = useContext(DatabaseContext)?.rowDocMap;
  const rowOrders = useRowOrdersSelector();
  const fields = useDatabaseFields();
  const [notFound, setNotFound] = useState(false);
  const [groupResult, setGroupResult] = useState<Map<string, Row[]>>(new Map());

  useEffect(() => {
    if (!fieldId || !rowOrders || !rows) return;

    const onConditionsChange = () => {
      const newResult = new Map<string, Row[]>();

      const field = fields.get(fieldId);

      if (!field) {
        setNotFound(true);
        setGroupResult(newResult);
        return;
      }

      const groupResult = groupByField(rowOrders, rows, field);

      if (!groupResult) {
        setGroupResult(newResult);
        return;
      }

      setGroupResult(groupResult);
    };

    onConditionsChange();

    const debounceConditionsChange = debounce(onConditionsChange, 200);

    fields.observeDeep(debounceConditionsChange);
    return () => {
      fields.unobserveDeep(debounceConditionsChange);
    };
  }, [fieldId, fields, rowOrders, rows]);

  const visibleColumns = columns.filter((column) => column.visible);

  return {
    fieldId,
    groupResult,
    columns: visibleColumns,
    notFound,
  };
}

export function useRowOrdersSelector() {
  const rows = useContext(DatabaseContext)?.rowDocMap;
  const [rowOrders, setRowOrders] = useState<Row[]>();
  const view = useDatabaseView();
  const sorts = view?.get(YjsDatabaseKey.sorts);
  const fields = useDatabaseFields();
  const filters = view?.get(YjsDatabaseKey.filters);

  useEffect(() => {
    const onConditionsChange = () => {
      const originalRowOrders = view?.get(YjsDatabaseKey.row_orders).toJSON();

      if (!originalRowOrders || !rows) return;

      if (sorts?.length === 0 && filters?.length === 0) {
        setRowOrders(originalRowOrders);
        return;
      }

      let rowOrders: Row[] | undefined;

      if (sorts?.length) {
        rowOrders = sortBy(originalRowOrders, sorts, fields, rows);
      }

      if (filters?.length) {
        rowOrders = filterBy(rowOrders ?? originalRowOrders, filters, fields, rows);
      }

      if (rowOrders) {
        setRowOrders(rowOrders);
      } else {
        setRowOrders(originalRowOrders);
      }
    };

    const debounceConditionsChange = debounce(onConditionsChange, 200);

    onConditionsChange();
    sorts?.observeDeep(debounceConditionsChange);
    filters?.observeDeep(debounceConditionsChange);
    fields?.observeDeep(debounceConditionsChange);
    rows?.observeDeep(debounceConditionsChange);

    return () => {
      sorts?.unobserveDeep(debounceConditionsChange);
      filters?.unobserveDeep(debounceConditionsChange);
      fields?.unobserveDeep(debounceConditionsChange);
      rows?.observeDeep(debounceConditionsChange);
    };
  }, [fields, rows, sorts, filters, view]);

  return rowOrders;
}

export function useCellSelector({ rowId, fieldId }: { rowId: string; fieldId: string }) {
  const row = useRowMeta(rowId);
  const cell = row?.get(YjsDatabaseKey.cells)?.get(fieldId);
  const [cellValue, setCellValue] = useState(() => (cell ? parseYDatabaseCellToCell(cell) : undefined));

  useEffect(() => {
    if (!cell) return;
    setCellValue(parseYDatabaseCellToCell(cell));
    const observerEvent = () => setCellValue(parseYDatabaseCellToCell(cell));

    cell.observe(observerEvent);

    return () => {
      cell.unobserve(observerEvent);
    };
  }, [cell]);

  return cellValue;
}
