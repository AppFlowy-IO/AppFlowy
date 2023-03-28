
export const iconSize = { width: 18, height: 18 };

export const command: Record<string, { title: string; key: string }> = {
  bold: {
    title: 'Bold',
    key: '⌘ + B',
  },
  underlined: {
    title: 'Underlined',
    key: '⌘ + U',
  },
  italic: {
    title: 'Italic',
    key: '⌘ + I',
  },
  code: {
    title: 'Mark as code',
    key: '⌘ + E',
  },
  strikethrough: {
    title: 'Strike through',
    key: '⌘ + Shift + S or ⌘ + Shift + X',
  },
};
