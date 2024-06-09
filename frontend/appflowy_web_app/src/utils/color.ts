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
function argbToRgba(color: string): string {
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

export function renderColor(color: string) {
  if (colorMap[color as ColorEnum]) {
    return colorMap[color as ColorEnum];
  }

  if (gradientMap[color as GradientEnum]) {
    return gradientMap[color as GradientEnum];
  }

  return argbToRgba(color);
}
