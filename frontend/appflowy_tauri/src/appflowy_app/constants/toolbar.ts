import { TextBlockToolbarGroup } from "../interfaces";

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

export const toolbarDefaultProps = {
  showGroups: [
    TextBlockToolbarGroup.ASK_AI,
    TextBlockToolbarGroup.BLOCK_SELECT,
    TextBlockToolbarGroup.ADD_LINK,
    TextBlockToolbarGroup.COMMENT,
    TextBlockToolbarGroup.TEXT_FORMAT,
    TextBlockToolbarGroup.TEXT_COLOR,
    TextBlockToolbarGroup.MENTION,
    TextBlockToolbarGroup.MORE,
  ],
};