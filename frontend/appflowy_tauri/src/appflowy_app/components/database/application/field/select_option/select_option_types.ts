import { SelectOptionColorPB, SelectOptionPB } from '@/services/backend';

export interface SelectOption {
  id: string;
  name: string;
  color: SelectOptionColorPB;
}

export function pbToSelectOption(pb: SelectOptionPB): SelectOption {
  return {
    id: pb.id,
    name: pb.name,
    color: pb.color,
  };
}
