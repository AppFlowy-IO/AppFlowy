import { Filter } from '@/application/database-yjs';

export enum SelectOptionColor {
  Purple = 'Purple',
  Pink = 'Pink',
  LightPink = 'LightPink',
  Orange = 'Orange',
  Yellow = 'Yellow',
  Lime = 'Lime',
  Green = 'Green',
  Aqua = 'Aqua',
  Blue = 'Blue',
}

export enum SelectOptionFilterCondition {
  OptionIs = 0,
  OptionIsNot = 1,
  OptionContains = 2,
  OptionDoesNotContain = 3,
  OptionIsEmpty = 4,
  OptionIsNotEmpty = 5,
}

export interface SelectOptionFilter extends Filter {
  condition: SelectOptionFilterCondition;
  optionIds: string[];
}

export interface SelectOption {
  id: string;
  name: string;
  color: SelectOptionColor;
}

export interface SelectTypeOption {
  disable_color: boolean;
  options: SelectOption[];
}
