import {
  DatabaseViewIdPB,
  GroupByFieldPayloadPB,
  MoveGroupPayloadPB,
  UpdateGroupPB,
} from '@/services/backend';
import {
  DatabaseEventGetGroups,
  DatabaseEventMoveGroup,
  DatabaseEventSetGroupByField,
  DatabaseEventUpdateGroup,
} from '@/services/backend/events/flowy-database2';
import { Group, pbToGroup } from './group_types';

export async function getGroups(viewId: string): Promise<Group[]> {
  const payload = DatabaseViewIdPB.fromObject({ value: viewId });

  const result = await DatabaseEventGetGroups(payload);

  return result.map(value => value.items.map(pbToGroup)).unwrap();
}

export async function setGroupByField(viewId: string, fieldId: string): Promise<void> {
  const payload = GroupByFieldPayloadPB.fromObject({
    view_id: viewId,
    field_id: fieldId,
  });

  const result = await DatabaseEventSetGroupByField(payload);

  return result.unwrap();
}

export async function updateGroup(
  viewId: string,
  group: {
    id: string,
    name?: string,
    visible?: boolean,
  },
): Promise<void> {
  const payload = UpdateGroupPB.fromObject({
    view_id: viewId,
    group_id: group.id,
    name: group.name,
    visible: group.visible,
  });

  const result = await DatabaseEventUpdateGroup(payload);

  return result.unwrap();
}

export async function moveGroup(viewId: string, fromGroupId: string, toGroupId: string): Promise<void> {
  const payload = MoveGroupPayloadPB.fromObject({
    view_id: viewId,
    from_group_id: fromGroupId,
    to_group_id: toGroupId,
  });

  const result = await DatabaseEventMoveGroup(payload);

  return result.unwrap();
}
