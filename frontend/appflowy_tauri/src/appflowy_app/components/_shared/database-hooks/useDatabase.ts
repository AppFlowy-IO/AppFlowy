import { useCallback, useEffect, useMemo, useState } from 'react';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import {
  databaseActions,
  DatabaseFieldMap,
  IDatabaseColumn,
  IDatabaseFilter,
  TDatabaseOperators,
} from '$app/stores/reducers/database/slice';
import { useAppDispatch } from '$app/stores/store';
import loadField from './loadField';
import { FieldInfo } from '$app/stores/effects/database/field/field_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import {
  FieldType,
  SelectOptionConditionPB,
  SelectOptionFilterPB,
  TextFilterConditionPB,
  TextFilterPB,
  ViewLayoutPB,
} from '@/services/backend';
import { DatabaseGroupController } from '$app/stores/effects/database/group/group_controller';
import { OnDragEndResponder } from 'react-beautiful-dnd';
import { AsyncQueue } from '$app/utils/async_queue';

export const useDatabase = (viewId: string, type?: ViewLayoutPB) => {
  const dispatch = useAppDispatch();
  const [controller, setController] = useState<DatabaseController>();
  const [rows, setRows] = useState<readonly RowInfo[]>([]);
  const [groups, setGroups] = useState<readonly DatabaseGroupController[]>([]);
  const [groupByFieldId, setGroupByFieldId] = useState('');

  useEffect(() => {
    if (!viewId.length) return;
    const c = new DatabaseController(viewId);

    setController(c);

    return () => void c.dispose();
  }, [viewId]);

  const loadFields = useCallback(
    async (fieldInfos: readonly FieldInfo[]) => {
      const fields: DatabaseFieldMap = {};
      const columns: IDatabaseColumn[] = [];

      for (const fieldInfo of fieldInfos) {
        const fieldPB = fieldInfo.field;

        columns.push({
          fieldId: fieldPB.id,
          sort: 'none',
          visible: fieldPB.visibility,
        });

        const field = await loadField(viewId, fieldInfo, dispatch);

        fields[field.fieldId] = field;
      }

      dispatch(databaseActions.updateFields({ fields }));
      dispatch(databaseActions.updateColumns({ columns }));
    },
    [viewId, dispatch]
  );

  const queue = useMemo(() => {
    return new AsyncQueue<readonly FieldInfo[]>(loadFields);
  }, [loadFields]);

  const transformCondition: (condition: number, fieldType: FieldType) => TDatabaseOperators = (condition, fieldType) => {
    switch (fieldType) {
      case FieldType.RichText:
        switch (condition) {
          case TextFilterConditionPB.Contains:
            return 'contains';
          case TextFilterConditionPB.DoesNotContain:
            return 'doesNotContain';
          case TextFilterConditionPB.EndsWith:
            return 'endsWith';
          case TextFilterConditionPB.StartsWith:
            return 'startWith';
          case TextFilterConditionPB.Is:
            return 'is';
          case TextFilterConditionPB.IsNot:
            return 'isNot';
          case TextFilterConditionPB.TextIsEmpty:
            return 'isEmpty';
          case TextFilterConditionPB.TextIsNotEmpty:
            return 'isNotEmpty';
          default:
            return 'is';
        }

      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        switch (condition) {
          case SelectOptionConditionPB.OptionIs:
            return 'is';
          case SelectOptionConditionPB.OptionIsNot:
            return 'isNot';
          case SelectOptionConditionPB.OptionIsEmpty:
            return 'isEmpty';
          case SelectOptionConditionPB.OptionIsNotEmpty:
            return 'isNotEmpty';
          default:
            return 'is';
        }

      default:
        return 'is';
    }
  };

  useEffect(() => {
    void (async () => {
      if (!controller) return;
      controller.subscribe({
        onRowsChanged: (rowInfos) => {
          // TODO: this is a hack to make sure that the row cache is updated
          setRows([...rowInfos]);
        },
        onFieldsChanged: (fieldInfos) => {
          queue.enqueue(fieldInfos);
        },
        onFiltersChanged: (filters) => {
          const reduxFilters = filters.map<IDatabaseFilter>((filter) => {
            switch (filter.field_type) {
              case FieldType.SingleSelect:
              case FieldType.MultiSelect:
                return {
                  logicalOperator: 'and',
                  fieldType: filter.field_type,
                  fieldId: filter.field_id,
                  id: filter.id,
                  operator: transformCondition((filter.data as SelectOptionFilterPB).condition, filter.field_type),
                  value: (filter.data as SelectOptionFilterPB).option_ids,
                };
              case FieldType.RichText:
                return {
                  logicalOperator: 'and',
                  fieldType: filter.field_type,
                  fieldId: filter.field_id,
                  id: filter.id,
                  operator: transformCondition((filter.data as TextFilterPB).condition, filter.field_type),
                  value: (filter.data as TextFilterPB).content,
                };

              default:
                return {
                  logicalOperator: 'and',
                  fieldType: filter.field_type,
                  fieldId: filter.field_id,
                  id: filter.id,
                  operator: 'is',
                  value: '',
                };
            }
          });

          dispatch(databaseActions.updateFilters({ filters: reduxFilters }));
        },
        onSortChanged: (sorts) => {
          dispatch(databaseActions.updateSorts({ sorts: [...sorts] }));
        },
      });

      const openResult = await controller.open();

      if (openResult.ok) {
        setRows(
          openResult.val.map((pb) => {
            return new RowInfo(viewId, controller.fieldController.fieldInfos, pb);
          })
        );
      }

      if (type === ViewLayoutPB.Board) {
        const fieldId = await controller.getGroupByFieldId();

        setGroupByFieldId(fieldId.unwrap());
        setGroups(controller.groups.value);
      }
    })();

    return () => {
      void controller?.dispose();
    };
  }, [controller, queue]);

  const onNewRowClick = async (index: number) => {
    if (!groups) return;
    if (!controller?.groups) return;
    const group = groups[index];

    await group.createRow();

    setGroups([...controller.groups.value]);
  };

  const onDragEnd: OnDragEndResponder = async (result) => {
    if (!controller) return;
    const { source, destination } = result;
    const group = groups.find((g) => g.groupId === source.droppableId);

    if (!group) return;

    if (source.droppableId === destination?.droppableId) {
      // move inside the block (group)
      await controller.exchangeGroupRow(
        group.rows[source.index].id,
        destination.droppableId,
        group.rows[destination.index].id
      );
    } else {
      // move to different block (group)
      if (!destination?.droppableId) return;
      await controller.moveGroupRow(group.rows[source.index].id, destination.droppableId);
    }
  };

  return { loadFields, controller, rows, groups, groupByFieldId, onNewRowClick, onDragEnd };
};
