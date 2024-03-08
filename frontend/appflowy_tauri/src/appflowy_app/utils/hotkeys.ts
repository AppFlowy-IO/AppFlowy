import isHotkey from 'is-hotkey';

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

export enum HOT_KEY_NAME {
  ALIGN_LEFT = 'align-left',
  ALIGN_CENTER = 'align-center',
  ALIGN_RIGHT = 'align-right',
  BOLD = 'bold',
  ITALIC = 'italic',
  UNDERLINE = 'underline',
  STRIKETHROUGH = 'strikethrough',
  CODE = 'code',
}

const defaultHotKeys = {
  [HOT_KEY_NAME.ALIGN_LEFT]: 'control+shift+l',
  [HOT_KEY_NAME.ALIGN_CENTER]: 'control+shift+e',
  [HOT_KEY_NAME.ALIGN_RIGHT]: 'control+shift+r',
  [HOT_KEY_NAME.BOLD]: 'mod+b',
  [HOT_KEY_NAME.ITALIC]: 'mod+i',
  [HOT_KEY_NAME.UNDERLINE]: 'mod+u',
  [HOT_KEY_NAME.STRIKETHROUGH]: 'mod+shift+s',
  [HOT_KEY_NAME.CODE]: 'mod+shift+c',
};

const replaceModifier = (hotkey: string) => {
  return hotkey.replace('mod', getModifier()).replace('control', 'ctrl');
};

export const createHotkey = (hotkeyName: HOT_KEY_NAME, customHotKeys?: Record<HOT_KEY_NAME, string>) => {
  const keys = customHotKeys || defaultHotKeys;
  const hotkey = keys[hotkeyName];

  return (event: KeyboardEvent) => {
    return isHotkey(hotkey, event);
  };
};

export const createHotKeyLabel = (hotkeyName: HOT_KEY_NAME, customHotKeys?: Record<HOT_KEY_NAME, string>) => {
  const keys = customHotKeys || defaultHotKeys;
  const hotkey = replaceModifier(keys[hotkeyName]);

  return hotkey
    .split('+')
    .map((key) => {
      return key === ' ' ? 'Space' : key.charAt(0).toUpperCase() + key.slice(1);
    })
    .join(' + ');
};
