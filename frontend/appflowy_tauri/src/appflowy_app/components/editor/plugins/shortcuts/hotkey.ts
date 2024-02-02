import { EditorMarkFormat } from '$app/application/document/document.types';

export const isMac = () => {
  return navigator.userAgent.includes('Mac OS X');
};

const MODIFIERS = {
  control: 'Ctrl',
  meta: '⌘',
};

export const getModifier = () => {
  return isMac() ? MODIFIERS.meta : MODIFIERS.control;
};

/**
 * Hotkeys shortcuts
 * @description
 * - bold: Mod+b
 * - italic: Mod+i
 * - underline: Mod+u
 * - strikethrough: Mod+Shift+s
 * - code: Mod+Shift+c
 */
export const getHotKeys: () => {
  [key: string]: { modifier: string; hotkey: string; markKey: EditorMarkFormat; markValue: string | boolean };
} = () => {
  const modifier = getModifier();

  return {
    [EditorMarkFormat.Bold]: {
      hotkey: 'mod+b',
      modifier: `${modifier} + B`,
      markKey: EditorMarkFormat.Bold,
      markValue: true,
    },
    [EditorMarkFormat.Italic]: {
      hotkey: 'mod+i',
      modifier: `${modifier} + I`,
      markKey: EditorMarkFormat.Italic,
      markValue: true,
    },
    [EditorMarkFormat.Underline]: {
      hotkey: 'mod+u',
      modifier: `${modifier} + U`,
      markKey: EditorMarkFormat.Underline,
      markValue: true,
    },
    [EditorMarkFormat.StrikeThrough]: {
      hotkey: 'mod+shift+s',
      modifier: `${modifier} + Shift + S`,
      markKey: EditorMarkFormat.StrikeThrough,
      markValue: true,
    },
    [EditorMarkFormat.Code]: {
      hotkey: 'mod+shift+c',
      modifier: `${modifier} + Shift + C`,
      markKey: EditorMarkFormat.Code,
      markValue: true,
    },
    'align-left': {
      hotkey: 'control+shift+l',
      modifier: `Ctrl + Shift + L`,
      markKey: EditorMarkFormat.Align,
      markValue: 'left',
    },
    'align-center': {
      hotkey: 'control+shift+e',
      modifier: `Ctrl + Shift + E`,
      markKey: EditorMarkFormat.Align,
      markValue: 'center',
    },
    'align-right': {
      hotkey: 'control+shift+r',
      modifier: `Ctrl + Shift + R`,
      markKey: EditorMarkFormat.Align,
      markValue: 'right',
    },
  };
};

export const getHotKey = (key: EditorMarkFormat) => {
  return getHotKeys()[key];
};
