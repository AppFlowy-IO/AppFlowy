import { GroupPB, GroupSettingPB } from '@/services/backend';
import { pbToRowMeta, RowMeta } from '../row';

export interface GroupSetting {
  id: string;
  fieldId: string;
}

export interface Group {
  id: string;
  isDefault: boolean;
  isVisible: boolean;
  fieldId: string;
  rows: RowMeta[];
}

export function pbToGroup(pb: GroupPB): Group {
  return {
    id: pb.group_id,
    isDefault: pb.is_default,
    isVisible: pb.is_visible,
    fieldId: pb.field_id,
    rows: pb.rows.map(pbToRowMeta),
  };
}

export function pbToGroupSetting(pb: GroupSettingPB): GroupSetting {
  return {
    id: pb.id,
    fieldId: pb.field_id,
  };
}
