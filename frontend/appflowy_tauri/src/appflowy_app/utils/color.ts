export enum ColorEnum {
  Purple = 'appflowy_them_color_tint1',
  Pink = 'appflowy_them_color_tint2',
  LightPink = 'appflowy_them_color_tint3',
  Orange = 'appflowy_them_color_tint4',
  Yellow = 'appflowy_them_color_tint5',
  Lime = 'appflowy_them_color_tint6',
  Green = 'appflowy_them_color_tint7',
  Aqua = 'appflowy_them_color_tint8',
  Blue = 'appflowy_them_color_tint9',
}

export const colorMap = {
  [ColorEnum.Purple]: 'var(--tint-purple)',
  [ColorEnum.Pink]: 'var(--tint-pink)',
  [ColorEnum.LightPink]: 'var(--tint-red)',
  [ColorEnum.Orange]: 'var(--tint-orange)',
  [ColorEnum.Yellow]: 'var(--tint-yellow)',
  [ColorEnum.Lime]: 'var(--tint-lime)',
  [ColorEnum.Green]: 'var(--tint-green)',
  [ColorEnum.Aqua]: 'var(--tint-aqua)',
  [ColorEnum.Blue]: 'var(--tint-blue)',
};

export function renderColor(color: string) {
  if (colorMap[color as ColorEnum]) {
    return colorMap[color as ColorEnum];
  }

  return color.replace('0x', '#');
}
