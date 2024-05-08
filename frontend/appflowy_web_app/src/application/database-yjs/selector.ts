import { FieldId, SortId, YDatabaseField, YjsDatabaseKey } from '@/application/collab.type';
import { MIN_COLUMN_WIDTH } from '@/application/database-yjs/const';
import { useDatabase, useGridRows, useViewId } from '@/application/database-yjs/context';
import { parseFilter } from '@/application/database-yjs/filter';
import { FieldType, FieldVisibility, Filter, SortCondition } from './database.type';
import { useEffect, useMemo, useState } from 'react';

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

export function useGridColumnsSelector(viewId: string, visibilitys: FieldVisibility[] = defaultVisible) {
  const database = useDatabase();
  const [columns, setColumns] = useState<Column[]>([]);

  useEffect(() => {
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
            visibility: parseInt(setting?.get(YjsDatabaseKey.visibility)) as FieldVisibility,
            wrap: setting?.get(YjsDatabaseKey.wrap),
          };
        })
        .filter((column) => visibilitys.includes(column.visibility));
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

export function useGridRowsSelector() {
  const rowOrders = useGridRows();

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

    field.observe(observerEvent);

    return () => {
      field.unobserve(observerEvent);
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
