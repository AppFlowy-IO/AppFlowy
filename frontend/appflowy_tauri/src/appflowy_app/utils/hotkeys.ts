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
  TOGGLE_TODO = 'toggle-todo',
  TOGGLE_COLLAPSE = 'toggle-collapse',
}

const defaultHotKeys = {
  [HOT_KEY_NAME.ALIGN_LEFT]: ['control+shift+l'],
  [HOT_KEY_NAME.ALIGN_CENTER]: ['control+shift+e'],
  [HOT_KEY_NAME.ALIGN_RIGHT]: ['control+shift+r'],
  [HOT_KEY_NAME.BOLD]: ['mod+b'],
  [HOT_KEY_NAME.ITALIC]: ['mod+i'],
  [HOT_KEY_NAME.UNDERLINE]: ['mod+u'],
  [HOT_KEY_NAME.STRIKETHROUGH]: ['mod+shift+s', 'mod+shift+x'],
  [HOT_KEY_NAME.CODE]: ['mod+e'],
  [HOT_KEY_NAME.TOGGLE_TODO]: ['mod+enter'],
  [HOT_KEY_NAME.TOGGLE_COLLAPSE]: ['mod+enter'],
};

const replaceModifier = (hotkey: string) => {
  return hotkey.replace('mod', getModifier()).replace('control', 'ctrl');
};

/**
 * Create a hotkey checker.
 * @example trigger strike through when user press "Cmd + Shift + S" or "Cmd + Shift + X"
 * @param hotkeyName
 * @param customHotKeys
 */
export const createHotkey = (hotkeyName: HOT_KEY_NAME, customHotKeys?: Record<HOT_KEY_NAME, string[]>) => {
  const keys = customHotKeys || defaultHotKeys;
  const hotkeys = keys[hotkeyName];

  return (event: KeyboardEvent) => {
    return hotkeys.some((hotkey) => {
      return isHotkey(hotkey, event);
    });
  };
};

/**
 * Create a hotkey label.
 * eg. "Ctrl + B / ⌘ + B"
 * @param hotkeyName
 * @param customHotKeys
 */
export const createHotKeyLabel = (hotkeyName: HOT_KEY_NAME, customHotKeys?: Record<HOT_KEY_NAME, string[]>) => {
  const keys = customHotKeys || defaultHotKeys;
  const hotkeys = keys[hotkeyName].map((key) => replaceModifier(key));

  return hotkeys
    .map((hotkey) =>
      hotkey
        .split('+')
        .map((key) => {
          return key === ' ' ? 'Space' : key.charAt(0).toUpperCase() + key.slice(1);
        })
        .join(' + ')
    )
    .join(' / ');
};
