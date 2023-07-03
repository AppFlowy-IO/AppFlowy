import isHotkey from 'is-hotkey';
import { Keyboard } from '$app/constants/document/keyboard';
import { TextAction } from '$app/interfaces/document';

export function isFormatHotkey(e: KeyboardEvent | React.KeyboardEvent<HTMLDivElement>) {
  return (
    isHotkey(Keyboard.keys.FORMAT.BOLD, e) ||
    isHotkey(Keyboard.keys.FORMAT.ITALIC, e) ||
    isHotkey(Keyboard.keys.FORMAT.UNDERLINE, e) ||
    isHotkey(Keyboard.keys.FORMAT.STRIKE, e) ||
    isHotkey(Keyboard.keys.FORMAT.CODE, e)
  );
}

export function parseFormat(e: KeyboardEvent | React.KeyboardEvent<HTMLDivElement>) {
  if (isHotkey(Keyboard.keys.FORMAT.BOLD, e)) {
    return TextAction.Bold;
  } else if (isHotkey(Keyboard.keys.FORMAT.ITALIC, e)) {
    return TextAction.Italic;
  } else if (isHotkey(Keyboard.keys.FORMAT.UNDERLINE, e)) {
    return TextAction.Underline;
  } else if (isHotkey(Keyboard.keys.FORMAT.STRIKE, e)) {
    return TextAction.Strikethrough;
  } else if (isHotkey(Keyboard.keys.FORMAT.CODE, e)) {
    return TextAction.Code;
  }
  return null;
}
