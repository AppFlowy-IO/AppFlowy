import { renderHook } from '@testing-library/react';
import {
  useCellSelector,
  useFieldSelector,
  useFieldsSelector,
  useFilterSelector,
  useFiltersSelector,
  useGroup,
  useGroupsSelector,
  usePrimaryFieldId,
  useRowDataSelector,
  useRowMetaSelector,
  useRowOrdersSelector,
  useRowsByGroup,
  useSortSelector,
  useSortsSelector,
} from '../selector';
import { useDatabaseViewId } from '../context';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import { withTestingDatabase } from '@/application/database-yjs/__tests__/withTestingData';
import { expect } from '@jest/globals';
import { YDoc, YjsDatabaseKey, YjsEditorKey, YSharedRoot } from '@/application/types';
import * as Y from 'yjs';
import { withNumberTestingField, withTestingFields } from '@/application/database-yjs/__tests__/withTestingField';
import { withTestingRows } from '@/application/database-yjs/__tests__/withTestingRows';

const wrapperCreator =
  (viewId: string, doc: YDoc, rowDocMap: Record<string, YDoc>) =>
    ({ children }: { children: React.ReactNode }) => {
      return (
        <DatabaseContextProvider
          iidIndex={viewId} viewId={viewId} databaseDoc={doc} rowDocMap={rowDocMap} readOnly={true}
        >
          {children}
        </DatabaseContextProvider>
      );
    };

describe('Database selector', () => {
  let wrapper: ({ children }: { children: React.ReactNode }) => JSX.Element;
  let rowDocMap: Record<string, YDoc>;
  let doc: YDoc;

  beforeEach(() => {
    const data = withTestingDatabase('1');

    doc = data.doc;
    rowDocMap = data.rowDocMap;
    wrapper = wrapperCreator('1', doc, rowDocMap);
  });

  it('should select a field', () => {
    const { result } = renderHook(() => useFieldSelector('number_field'), { wrapper });

    const tempDoc = new Y.Doc();
    const field = withNumberTestingField();

    tempDoc.getMap().set('number_field', field);

    expect(result.current.field?.toJSON()).toEqual(field.toJSON());
  });

  it('should select all fields', () => {
    const { result } = renderHook(() => useFieldsSelector(), { wrapper });

    expect(result.current.map((item) => item.fieldId)).toEqual(Array.from(withTestingFields().keys()));
  });

  it('should select all filters', () => {
    const { result } = renderHook(() => useFiltersSelector(), { wrapper });

    expect(result.current).toEqual(['filter_multi_select_field']);
  });

  it('should select a filter', () => {
    const { result } = renderHook(() => useFilterSelector('filter_multi_select_field'), { wrapper });

    expect(result.current).toEqual({
      content: '1,3',
      condition: 2,
      fieldId: 'multi_select_field',
      id: 'filter_multi_select_field',
      filterType: NaN,
      optionIds: ['1', '3'],
    });
  });

  it('should select all sorts', () => {
    const { result } = renderHook(() => useSortsSelector(), { wrapper });

    expect(result.current).toEqual(['sort_asc_text_field']);
  });

  it('should select a sort', () => {
    const { result } = renderHook(() => useSortSelector('sort_asc_text_field'), { wrapper });

    expect(result.current).toEqual({
      fieldId: 'text_field',
      id: 'sort_asc_text_field',
      condition: 0,
    });
  });

  it('should select all groups', () => {
    const { result } = renderHook(() => useGroupsSelector(), { wrapper });

    expect(result.current).toEqual(['g:single_select_field']);
  });

  it('should select a group', () => {
    const { result } = renderHook(() => useGroup('g:single_select_field'), { wrapper });

    expect(result.current).toEqual({
      fieldId: 'single_select_field',
      columns: [
        {
          id: '1',
          visible: true,
        },
        {
          id: 'single_select_field',
          visible: true,
        },
      ],
    });
  });

  it('should select rows by group', () => {
    const { result } = renderHook(() => useRowsByGroup('g:single_select_field'), { wrapper });

    const { fieldId, columns, notFound, groupResult } = result.current;

    expect(fieldId).toEqual('single_select_field');
    expect(columns).toEqual([
      {
        id: '1',
        visible: true,
      },
      {
        id: 'single_select_field',
        visible: true,
      },
    ]);
    expect(notFound).toBeFalsy();

    expect(groupResult).toEqual(
      new Map([
        [
          '1',
          [
            { id: '1', height: 37 },
            { id: '7', height: 37 },
          ],
        ],
        [
          '2',
          [
            { id: '2', height: 37 },
            { id: '8', height: 37 },
            { id: '5', height: 37 },
          ],
        ],
        [
          '3',
          [
            { id: '9', height: 37 },
            { id: '3', height: 37 },
            { id: '6', height: 37 },
          ],
        ],
      ]),
    );
  });

  it('should select all row orders', () => {
    const { result } = renderHook(() => useRowOrdersSelector(), { wrapper });

    expect(result.current?.map((item) => item.id).join(',')).toEqual('9,2,3,1,6,8,5,7');
  });

  it('should select a row data', () => {
    const rows = withTestingRows();
    const { result } = renderHook(() => useRowDataSelector(rows[0].id), { wrapper });

    expect(result.current.row?.toJSON()).toEqual(
      rowDocMap[rows[0].id]?.getMap(YjsEditorKey.data_section)?.get(YjsEditorKey.database_row)?.toJSON(),
    );
  });

  it('should select a cell', () => {
    const rows = withTestingRows();
    const { result } = renderHook(
      () =>
        useCellSelector({
          rowId: rows[0].id,
          fieldId: 'number_field',
        }),
      { wrapper },
    );

    expect(result.current).toEqual({
      createdAt: NaN,
      data: 123,
      fieldType: 1,
      lastModified: NaN,
    });
  });

  it('should select a primary field id', () => {
    const { result } = renderHook(() => usePrimaryFieldId(), { wrapper });

    expect(result.current).toEqual('text_field');
  });

  it('should select a row meta', () => {
    const rows = withTestingRows();
    const { result } = renderHook(() => useRowMetaSelector(rows[0].id), { wrapper });

    expect(result.current?.documentId).not.toBeNull();
  });

  it('should select view id', () => {
    const { result } = renderHook(() => useDatabaseViewId(), { wrapper });

    expect(result.current).toEqual('1');
  });

  it('should select all rows if filter is not found', () => {
    const view = (doc.get(YjsEditorKey.data_section) as YSharedRoot)
      .get(YjsEditorKey.database)
      .get(YjsDatabaseKey.views)
      .get('1');

    view.set(YjsDatabaseKey.filters, new Y.Array());

    const { result } = renderHook(() => useRowOrdersSelector(), { wrapper });

    expect(result.current?.map((item) => item.id).join(',')).toEqual('9,2,3,4,1,6,10,8,5,7');
  });

  it('should select original row orders if sorts is not found', () => {
    const view = (doc.get(YjsEditorKey.data_section) as YSharedRoot)
      .get(YjsEditorKey.database)
      .get(YjsDatabaseKey.views)
      .get('1');

    view.set(YjsDatabaseKey.sorts, new Y.Array());

    const { result } = renderHook(() => useRowOrdersSelector(), { wrapper });

    expect(result.current?.map((item) => item.id).join(',')).toEqual('1,2,3,5,6,7,8,9');
  });

  it('should select all rows if filters and sorts are not found', () => {
    const view = (doc.get(YjsEditorKey.data_section) as YSharedRoot)
      .get(YjsEditorKey.database)
      .get(YjsDatabaseKey.views)
      .get('1');

    view.set(YjsDatabaseKey.filters, new Y.Array());
    view.set(YjsDatabaseKey.sorts, new Y.Array());

    const { result } = renderHook(() => useRowOrdersSelector(), { wrapper });

    expect(result.current?.map((item) => item.id).join(',')).toEqual('1,2,3,4,5,6,7,8,9,10');
  });
});
