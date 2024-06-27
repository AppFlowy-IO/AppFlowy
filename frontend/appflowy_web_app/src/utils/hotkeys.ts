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
  LEFT = 'left',
  RIGHT = 'right',
  SELECT_ALL = 'select-all',
  ESCAPE = 'escape',
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
  INDENT_BLOCK = 'indent-block',
  OUTDENT_BLOCK = 'outdent-block',
  INSERT_SOFT_BREAK = 'insert-soft-break',
  SPLIT_BLOCK = 'split-block',
  BACKSPACE = 'backspace',
  OPEN_LINK = 'open-link',
  OPEN_LINKS = 'open-links',
  EXTEND_LINE_BACKWARD = 'extend-line-backward',
  EXTEND_LINE_FORWARD = 'extend-line-forward',
  PASTE = 'paste',
  PASTE_PLAIN_TEXT = 'paste-plain-text',
  HIGH_LIGHT = 'high-light',
  EXTEND_DOCUMENT_BACKWARD = 'extend-document-backward',
  EXTEND_DOCUMENT_FORWARD = 'extend-document-forward',
  SCROLL_TO_TOP = 'scroll-to-top',
  SCROLL_TO_BOTTOM = 'scroll-to-bottom',
  FORMAT_LINK = 'format-link',
  FIND_REPLACE = 'find-replace',
  /**
   * Navigation
   */
  TOGGLE_THEME = 'toggle-theme',
  TOGGLE_SIDEBAR = 'toggle-sidebar',
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
  [HOT_KEY_NAME.SELECT_ALL]: ['mod+a'],
  [HOT_KEY_NAME.ESCAPE]: ['esc'],
  [HOT_KEY_NAME.INDENT_BLOCK]: ['tab'],
  [HOT_KEY_NAME.OUTDENT_BLOCK]: ['shift+tab'],
  [HOT_KEY_NAME.SPLIT_BLOCK]: ['enter'],
  [HOT_KEY_NAME.INSERT_SOFT_BREAK]: ['shift+enter'],
  [HOT_KEY_NAME.BACKSPACE]: ['backspace', 'shift+backspace'],
  [HOT_KEY_NAME.OPEN_LINK]: ['opt+enter'],
  [HOT_KEY_NAME.OPEN_LINKS]: ['opt+shift+enter'],
  [HOT_KEY_NAME.EXTEND_LINE_BACKWARD]: ['opt+shift+left'],
  [HOT_KEY_NAME.EXTEND_LINE_FORWARD]: ['opt+shift+right'],
  [HOT_KEY_NAME.PASTE]: ['mod+v'],
  [HOT_KEY_NAME.PASTE_PLAIN_TEXT]: ['mod+shift+v'],
  [HOT_KEY_NAME.HIGH_LIGHT]: ['mod+shift+h'],
  [HOT_KEY_NAME.EXTEND_DOCUMENT_BACKWARD]: ['mod+shift+up'],
  [HOT_KEY_NAME.EXTEND_DOCUMENT_FORWARD]: ['mod+shift+down'],
  [HOT_KEY_NAME.SCROLL_TO_TOP]: ['home'],
  [HOT_KEY_NAME.SCROLL_TO_BOTTOM]: ['end'],
  [HOT_KEY_NAME.TOGGLE_THEME]: ['mod+shift+l'],
  [HOT_KEY_NAME.TOGGLE_SIDEBAR]: ['mod+.'],
  [HOT_KEY_NAME.FORMAT_LINK]: ['mod+k'],
  [HOT_KEY_NAME.LEFT]: ['left'],
  [HOT_KEY_NAME.RIGHT]: ['right'],
  [HOT_KEY_NAME.FIND_REPLACE]: ['mod+f'],
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
