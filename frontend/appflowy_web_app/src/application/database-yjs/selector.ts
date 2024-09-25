import {
  FieldId,
  SortId,
  YDatabase,
  YDatabaseField, YDatabaseMetas, YDatabaseRow,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/types';
import { getCell, metaIdFromRowId, MIN_COLUMN_WIDTH } from '@/application/database-yjs/const';
import {
  useDatabase,
  useDatabaseFields,
  useDatabaseView,
  useRowDocMap,
  useViewId,
} from '@/application/database-yjs/context';
import { filterBy, parseFilter } from '@/application/database-yjs/filter';
import { groupByField } from '@/application/database-yjs/group';
import { sortBy } from '@/application/database-yjs/sort';
import { parseYDatabaseCellToCell } from '@/application/database-yjs/cell.parse';
import { DateTimeCell } from '@/application/database-yjs/cell.type';
import dayjs from 'dayjs';
import { debounce } from 'lodash-es';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { CalendarLayoutSetting, FieldType, FieldVisibility, Filter, RowMetaKey, SortCondition } from './database.type';

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

export function useDatabaseViewsSelector (_iidIndex: string, visibleViewIds?: string[]) {
  const database = useDatabase();

  const views = database?.get(YjsDatabaseKey.views);
  const [viewIds, setViewIds] = useState<string[]>([]);
  const childViews = useMemo(() => {
    return viewIds.map((viewId) => views?.get(viewId));
  }, [viewIds, views]);

  useEffect(() => {
    if (!views) return;

    const observerEvent = () => {
      const viewsObj = views.toJSON() as Record<
        string,
        {
          created_at: number;
        }
      >;

      const viewsSorted = Object.entries(viewsObj).sort((a, b) => {
        const [, viewA] = a;
        const [, viewB] = b;

        return Number(viewB.created_at) - Number(viewA.created_at);
      });

      setViewIds(
        viewsSorted
          .map(([key]) => key)
          .filter((id) => {
            return !visibleViewIds || visibleViewIds.includes(id);
          }),
      );
    };

    observerEvent();
    views.observe(observerEvent);

    return () => {
      views.unobserve(observerEvent);
    };
  }, [views, visibleViewIds]);

  return {
    childViews,
    viewIds,
  };
}

export function useFieldsSelector (visibilitys: FieldVisibility[] = defaultVisible) {
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

      const fieldIds = (fieldsOrder.toJSON() as { id: string }[]).map((item) => item.id);

      return fieldIds
        .map((fieldId) => {
          const setting = fieldSettings.get(fieldId);

          return {
            fieldId,
            width: parseInt(setting?.get(YjsDatabaseKey.width)) || MIN_COLUMN_WIDTH,
            visibility: Number(
              setting?.get(YjsDatabaseKey.visibility) || FieldVisibility.AlwaysShown,
            ) as FieldVisibility,
            wrap: setting?.get(YjsDatabaseKey.wrap) ?? true,
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

export function useFieldSelector (fieldId: string) {
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

export function useFiltersSelector () {
  const database = useDatabase();
  const viewId = useViewId();
  const [filters, setFilters] = useState<string[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const filterOrders = view?.get(YjsDatabaseKey.filters);

    if (!filterOrders) return;

    const getFilters = () => {
      return (filterOrders.toJSON() as { id: string }[]).map((item) => item.id);
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

export function useFilterSelector (filterId: string) {
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

export function useSortsSelector () {
  const database = useDatabase();
  const viewId = useViewId();
  const [sorts, setSorts] = useState<string[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);
    const sortOrders = view?.get(YjsDatabaseKey.sorts);

    if (!sortOrders) return;

    const getSorts = () => {
      return (sortOrders.toJSON() as { id: string }[]).map((item) => item.id);
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

export function useSortSelector (sortId: SortId) {
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

export function useGroupsSelector () {
  const database = useDatabase();
  const viewId = useViewId();
  const [groups, setGroups] = useState<string[]>([]);

  useEffect(() => {
    if (!viewId) return;
    const view = database?.get(YjsDatabaseKey.views)?.get(viewId);

    const groupOrders = view?.get(YjsDatabaseKey.groups);

    if (!groupOrders) return;

    const getGroups = () => {
      return (groupOrders.toJSON() as { id: string }[]).map((item) => item.id);
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

export function useGroup (groupId: string) {
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

export function useRowsByGroup (groupId: string) {
  const { columns, fieldId } = useGroup(groupId);
  const rows = useRowDocMap();
  const rowOrders = useRowOrdersSelector();

  const fields = useDatabaseFields();
  const [notFound, setNotFound] = useState(false);
  const [groupResult, setGroupResult] = useState<Map<string, Row[]>>(new Map());
  const view = useDatabaseView();
  const layoutSetting = view?.get(YjsDatabaseKey.layout_settings)?.get('1');

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

    fields.observeDeep(onConditionsChange);
    return () => {
      fields.unobserveDeep(onConditionsChange);
    };
  }, [fieldId, fields, rowOrders, rows]);

  const visibleColumns = columns.filter((column) => {
    if (column.id === fieldId) return !layoutSetting?.get(YjsDatabaseKey.hide_ungrouped_column);
    return column.visible;
  });

  return {
    fieldId,
    groupResult,
    columns: visibleColumns,
    notFound,
  };
}

export function useRowOrdersSelector () {
  const rows = useRowDocMap();
  const [rowOrders, setRowOrders] = useState<Row[]>();
  const view = useDatabaseView();
  const sorts = view?.get(YjsDatabaseKey.sorts);
  const fields = useDatabaseFields();
  const filters = view?.get(YjsDatabaseKey.filters);
  const onConditionsChange = useCallback(() => {
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
  }, [fields, filters, rows, sorts, view]);

  useEffect(() => {
    onConditionsChange();
  }, [onConditionsChange]);

  useEffect(() => {
    const throttleChange = debounce(onConditionsChange, 200);

    view?.get(YjsDatabaseKey.row_orders)?.observeDeep(throttleChange);
    sorts?.observeDeep(throttleChange);
    filters?.observeDeep(throttleChange);
    fields?.observeDeep(throttleChange);

    return () => {
      view?.get(YjsDatabaseKey.row_orders)?.unobserveDeep(throttleChange);
      sorts?.unobserveDeep(throttleChange);
      filters?.unobserveDeep(throttleChange);
      fields?.unobserveDeep(throttleChange);
    };
  }, [onConditionsChange, view, fields, filters, sorts]);

  return rowOrders;
}

export function useRowDataSelector (rowId: string) {
  const rowMap = useRowDocMap();
  const [row, setRow] = useState<YDatabaseRow | null>(null);

  useEffect(() => {
    const rowDoc = rowMap?.[rowId];

    if (!rowDoc || !rowDoc.share.has(YjsEditorKey.data_section)) return;
    const rowSharedRoot = rowDoc?.getMap(YjsEditorKey.data_section);
    const row = rowSharedRoot?.get(YjsEditorKey.database_row);

    setRow(row);
  }, [rowId, rowMap]);
  return {
    row,
  };
}

export function useCellSelector ({ rowId, fieldId }: { rowId: string; fieldId: string }) {
  const { row } = useRowDataSelector(rowId);
  const cell = row?.get(YjsDatabaseKey.cells)?.get(fieldId);

  const [cellValue, setCellValue] = useState(() => (cell ? parseYDatabaseCellToCell(cell) : undefined));

  useEffect(() => {
    if (!cell) return;
    setCellValue(parseYDatabaseCellToCell(cell));
    const observerEvent = () => setCellValue(parseYDatabaseCellToCell(cell));

    cell.observeDeep(observerEvent);

    return () => {
      cell.unobserveDeep(observerEvent);
    };
  }, [cell]);

  return cellValue;
}

export interface CalendarEvent {
  start?: Date;
  end?: Date;
  id: string;
}

export function useCalendarEventsSelector () {
  const setting = useCalendarLayoutSetting();
  const filedId = setting.fieldId;
  const { field } = useFieldSelector(filedId);
  const rowOrders = useRowOrdersSelector();
  const rows = useRowDocMap();
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [emptyEvents, setEmptyEvents] = useState<CalendarEvent[]>([]);

  useEffect(() => {
    if (!field || !rowOrders || !rows) return;
    const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;

    if (fieldType !== FieldType.DateTime) return;
    const newEvents: CalendarEvent[] = [];
    const emptyEvents: CalendarEvent[] = [];

    rowOrders?.forEach((row) => {
      const cell = getCell(row.id, filedId, rows);

      if (!cell) {
        emptyEvents.push({
          id: `${row.id}:${filedId}`,
        });
        return;
      }

      const value = parseYDatabaseCellToCell(cell) as DateTimeCell;

      if (!value || !value.data) {
        emptyEvents.push({
          id: `${row.id}:${filedId}`,
        });
        return;
      }

      const getDate = (timestamp: string) => {
        const dayjsResult = timestamp.length === 10 ? dayjs.unix(Number(timestamp)) : dayjs(timestamp);

        return dayjsResult.toDate();
      };

      newEvents.push({
        id: `${row.id}:${filedId}`,
        start: getDate(value.data),
        end: value.endTimestamp && value.isRange ? getDate(value.endTimestamp) : getDate(value.data),
      });
    });

    setEvents(newEvents);
    setEmptyEvents(emptyEvents);
  }, [field, rowOrders, rows, filedId]);

  return { events, emptyEvents };
}

export function useCalendarLayoutSetting () {
  const view = useDatabaseView();
  const layoutSetting = view?.get(YjsDatabaseKey.layout_settings)?.get('2');
  const [setting, setSetting] = useState<CalendarLayoutSetting>({
    fieldId: '',
    firstDayOfWeek: 0,
    showWeekNumbers: true,
    showWeekends: true,
    layout: 0,
  });

  useEffect(() => {
    const observerHandler = () => {
      setSetting({
        fieldId: layoutSetting?.get(YjsDatabaseKey.field_id) as string,
        firstDayOfWeek: Number(layoutSetting?.get(YjsDatabaseKey.first_day_of_week)),
        showWeekNumbers: Boolean(layoutSetting?.get(YjsDatabaseKey.show_week_numbers)),
        showWeekends: Boolean(layoutSetting?.get(YjsDatabaseKey.show_weekends)),
        layout: Number(layoutSetting?.get(YjsDatabaseKey.layout_ty)),
      });
    };

    observerHandler();
    layoutSetting?.observe(observerHandler);
    return () => {
      layoutSetting?.unobserve(observerHandler);
    };
  }, [layoutSetting]);

  return setting;
}

export function getPrimaryFieldId (database: YDatabase) {
  const fields = database?.get(YjsDatabaseKey.fields);

  return Array.from(fields?.keys() || []).find((fieldId) => {
    return fields?.get(fieldId)?.get(YjsDatabaseKey.is_primary);
  });
}

export function usePrimaryFieldId () {
  const database = useDatabase();
  const [primaryFieldId, setPrimaryFieldId] = useState<string | null>(null);

  useEffect(() => {
    setPrimaryFieldId(getPrimaryFieldId(database) || null);
  }, [database]);

  return primaryFieldId;
}

export interface RowMeta {
  documentId: string;
  cover: string;
  icon: string;
  isEmptyDocument: boolean;
}

const metaIdMapFromRowIdMap = new Map<string, Map<RowMetaKey, string>>();

function getMetaIdMap (rowId: string) {
  const hasMetaIdMap = metaIdMapFromRowIdMap.has(rowId);

  if (!hasMetaIdMap) {
    const parser = metaIdFromRowId(rowId);
    const map = new Map<RowMetaKey, string>();

    map.set(RowMetaKey.IconId, parser(RowMetaKey.IconId));
    map.set(RowMetaKey.CoverId, parser(RowMetaKey.CoverId));
    map.set(RowMetaKey.DocumentId, parser(RowMetaKey.DocumentId));
    map.set(RowMetaKey.IsDocumentEmpty, parser(RowMetaKey.IsDocumentEmpty));
    metaIdMapFromRowIdMap.set(rowId, map);
    return map;
  }

  return metaIdMapFromRowIdMap.get(rowId) as Map<RowMetaKey, string>;
}

export const useRowMetaSelector = (rowId: string) => {
  const [meta, setMeta] = useState<RowMeta | null>();
  const rowMap = useRowDocMap();

  const updateMeta = useCallback(() => {

    const row = rowMap?.[rowId];

    if (!row || !row.share.has(YjsEditorKey.data_section)) return;

    const rowSharedRoot = row.getMap(YjsEditorKey.data_section);

    const yMeta = rowSharedRoot?.get(YjsEditorKey.meta);

    if (!yMeta) return;

    const metaKeyMap = getMetaIdMap(rowId);

    const iconKey = metaKeyMap.get(RowMetaKey.IconId) ?? '';
    const coverKey = metaKeyMap.get(RowMetaKey.CoverId) ?? '';
    const documentId = metaKeyMap.get(RowMetaKey.DocumentId) ?? '';
    const isEmptyDocumentKey = metaKeyMap.get(RowMetaKey.IsDocumentEmpty) ?? '';
    const metaJson = yMeta.toJSON();

    const icon = metaJson[iconKey];
    let cover = '';

    try {
      cover = metaJson[coverKey] ? JSON.parse(metaJson[coverKey])?.url : '';
    } catch (e) {
      // do nothing
    }

    const isEmptyDocument = metaJson[isEmptyDocumentKey];

    setMeta({
      icon,
      cover,
      documentId,
      isEmptyDocument,
    });
  }, [rowId, rowMap]);

  useEffect(() => {
    if (!rowMap) return;
    updateMeta();
    const observerEvent = () => updateMeta();

    const rowDoc = rowMap[rowId];

    if (!rowDoc || !rowDoc.share.has(YjsEditorKey.data_section)) return;
    const rowSharedRoot = rowDoc.getMap(YjsEditorKey.data_section);
    const meta = rowSharedRoot?.get(YjsEditorKey.meta) as YDatabaseMetas;

    meta?.observeDeep(observerEvent);
    return () => {
      meta?.unobserveDeep(observerEvent);
    };
  }, [rowId, rowMap, updateMeta]);

  return meta;
};
