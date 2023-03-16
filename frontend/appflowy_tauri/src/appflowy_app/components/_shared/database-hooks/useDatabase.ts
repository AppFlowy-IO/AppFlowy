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
        onGroupByField: (g) => {
          console.log('on group by field: ', g);
        },
      });
      await controller.open();

      if (type === ViewLayoutTypePB.Board) {
        setGroups(controller.groups.value);
      }
    })();
  }, [controller]);

  const onNewRowClick = async (index: number) => {
    if (!groups) return;
    if (!controller?.groups) return;
    const group = groups[index];
    await group.createRow();

    const newGroups = controller.groups.value;

    newGroups.forEach((g) => {
      console.log(g.name, g.rows);
    });

    setGroups([...controller.groups.value]);
  };

  const onDragEnd: OnDragEndResponder = async (result) => {
    const { source, destination } = result;
    // move inside the block (group)
    if (source.droppableId === destination?.droppableId) {
      const group = groups.find((g) => g.groupId === source.droppableId);
      if (!group || !controller) return;
      await controller.exchangeRow(group.rows[source.index].id, group.rows[destination.index].id);
    }
  };

  return { loadFields, controller, rows, groups, onNewRowClick, onDragEnd };
};
