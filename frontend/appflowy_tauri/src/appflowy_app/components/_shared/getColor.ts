import { SelectOptionColorPB } from '../../../services/backend';

export const getBgColor = (color: SelectOptionColorPB | undefined): string => {
  switch (color) {
    case SelectOptionColorPB.Purple:
      return 'bg-tint-purple';
    case SelectOptionColorPB.Pink:
      return 'bg-tint-pink';
    case SelectOptionColorPB.LightPink:
      return 'bg-tint-red';
    case SelectOptionColorPB.Orange:
      return 'bg-tint-orange';
    case SelectOptionColorPB.Yellow:
      return 'bg-tint-yellow';
    case SelectOptionColorPB.Lime:
      return 'bg-tint-lime';
    case SelectOptionColorPB.Green:
      return 'bg-tint-green';
    case SelectOptionColorPB.Aqua:
      return 'bg-tint-aqua';
    case SelectOptionColorPB.Blue:
      return 'bg-tint-blue';
    default:
      return '';
  }
};
