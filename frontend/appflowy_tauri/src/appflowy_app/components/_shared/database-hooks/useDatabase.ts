import { useEffect, useState } from 'react';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { databaseActions, DatabaseFieldMap, IDatabaseColumn } from '$app/stores/reducers/database/slice';
import { useAppDispatch } from '$app/stores/store';
import loadField from './loadField';
import { FieldInfo } from '$app/stores/effects/database/field/field_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { ViewLayoutTypePB } from '@/services/backend';
import { DatabaseGroupController } from '$app/stores/effects/database/group/group_controller';
import { OnDragEndResponder } from 'react-beautiful-dnd';

export const useDatabase = (viewId: string, type?: ViewLayoutTypePB) => {
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

  const loadFields = async (fieldInfos: readonly FieldInfo[]) => {
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
  };

  useEffect(() => {
    if (!controller) return;

    void (async () => {
      controller.subscribe({
        onRowsChanged: (rowInfos) => {
          setRows(rowInfos);
        },
        onFieldsChanged: (fieldInfos) => {
          void loadFields(fieldInfos);
        },
      });
      await controller.open();

      if (type === ViewLayoutTypePB.Board) {
        const fieldId = await controller.getGroupByFieldId();
        setGroupByFieldId(fieldId.unwrap());
        setGroups(controller.groups.value);
      }
    })();
  }, [controller]);

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
      await controller.exchangeRow(group.rows[source.index].id, group.rows[destination.index].id);
    } else {
      // move to different block (group)
      if (!destination?.droppableId) return;
      await controller.moveRow(group.rows[source.index].id, destination.droppableId);
    }
  };

  return { loadFields, controller, rows, groups, groupByFieldId, onNewRowClick, onDragEnd };
};
