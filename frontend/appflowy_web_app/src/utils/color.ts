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

export enum GradientEnum {
  gradient1 = 'appflowy_them_color_gradient1',
  gradient2 = 'appflowy_them_color_gradient2',
  gradient3 = 'appflowy_them_color_gradient3',
  gradient4 = 'appflowy_them_color_gradient4',
  gradient5 = 'appflowy_them_color_gradient5',
  gradient6 = 'appflowy_them_color_gradient6',
  gradient7 = 'appflowy_them_color_gradient7',
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

export const gradientMap = {
  [GradientEnum.gradient1]: 'var(--gradient1)',
  [GradientEnum.gradient2]: 'var(--gradient2)',
  [GradientEnum.gradient3]: 'var(--gradient3)',
  [GradientEnum.gradient4]: 'var(--gradient4)',
  [GradientEnum.gradient5]: 'var(--gradient5)',
  [GradientEnum.gradient6]: 'var(--gradient6)',
  [GradientEnum.gradient7]: 'var(--gradient7)',
};

// Convert ARGB to RGBA
// Flutter uses ARGB, but CSS uses RGBA
function argbToRgba (color: string): string {
  const hex = color.replace(/^#|0x/, '');

  const hasAlpha = hex.length === 8;

  if (!hasAlpha) {
    return color.replace('0x', '#');
  }

  const r = parseInt(hex.slice(2, 4), 16);
  const g = parseInt(hex.slice(4, 6), 16);
  const b = parseInt(hex.slice(6, 8), 16);
  const a = hasAlpha ? parseInt(hex.slice(0, 2), 16) / 255 : 1;

  return `rgba(${r}, ${g}, ${b}, ${a})`;
}

export function renderColor (color: string) {
  if (colorMap[color as ColorEnum]) {
    return colorMap[color as ColorEnum];
  }

  if (gradientMap[color as GradientEnum]) {
    return gradientMap[color as GradientEnum];
  }

  return argbToRgba(color);
}

export function stringToColor (string: string, colorArray?: string[]) {
  let hash = 0;
  let i;

  /* eslint-disable no-bitwise */
  for (i = 0; i < string.length; i += 1) {
    hash = string.charCodeAt(i) + ((hash << 5) - hash);
  }

  if (colorArray) {
    return colorArray[string.slice(0, 1).charCodeAt(0) % colorArray.length];
  }

  let color = '#';

  for (i = 0; i < 3; i += 1) {
    const value = (hash >> (i * 8)) & 0xff;

    color += `00${value.toString(16)}`.slice(-2);
  }
  /* eslint-enable no-bitwise */

  return color;
}

const colorDefaultArray: string[] = [
  '#5287D8',
  '#6E9DE3',
  '#8BB3ED',
  '#A7C9F7',
  '#979EB6',
  '#A2A8BF',
  '#ACB2C8',
  '#C1C7DA',
  '#E8AF53',
  '#E6C25A',
  '#E6D26F',
  '#E6E288',
  '#589599',
  '#68AD8E',
  '#79C47F',
  '#8CDB6A',
  '#AA94DC',
  '#C49EEB',
  '#BAACEE',
  '#D5C4FB',
  '#F597D2',
  '#FCB2E3',
  '#FDC5E8',
  '#F8D2E1',
  '#D1D269',
  '#C7C98D',
  '#CED09B',
  '#DAD9B6',
  '#DDD2C6',
  '#DDD6C7',
  '#EADED3',
  '#FED5C4',
  '#72A7D8',
  '#8FCAE3',
  '#64B3DA',
  '#52B2D4',
  '#90A4FF',
  '#A8BEF4',
  '#AEBDFF',
  '#C2CDFF',
  '#86C1B7',
  '#A6D8D0',
  '#A7D7A8',
  '#C8E4C9',
  '#FF9494',
  '#FFBDBD',
  '#DCA8A8',
  '#E3C4C4',
];

export function stringAvatar (name: string, colorArray: string[] = colorDefaultArray) {
  if (!name) {
    return null;
  }

  return {
    sx: {
      bgcolor: stringToColor(name, colorArray),
    },
    children: `${name.split('')[0]}`,
  };
}
