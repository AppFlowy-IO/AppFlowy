import { SelectOptionColorPB } from '../../../services/backend';

export const getBgColor = (color: SelectOptionColorPB | undefined): string => {
  switch (color) {
    case SelectOptionColorPB.Purple:
      return 'bg-tint-1';
    case SelectOptionColorPB.Pink:
      return 'bg-tint-2';
    case SelectOptionColorPB.LightPink:
      return 'bg-tint-3';
    case SelectOptionColorPB.Orange:
      return 'bg-tint-4';
    case SelectOptionColorPB.Yellow:
      return 'bg-tint-5';
    case SelectOptionColorPB.Lime:
      return 'bg-tint-6';
    case SelectOptionColorPB.Green:
      return 'bg-tint-7';
    case SelectOptionColorPB.Aqua:
      return 'bg-tint-8';
    case SelectOptionColorPB.Blue:
      return 'bg-tint-9';
    default:
      return '';
  }
};
