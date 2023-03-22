import isHotkey from 'is-hotkey';
import { toggleFormat } from './format';
import { Editor } from 'slate';

const HOTKEYS: Record<string, string> = {
  'mod+b': 'bold',
  'mod+i': 'italic',
  'mod+u': 'underline',
  'mod+e': 'code',
  'mod+shift+X': 'strikethrough',
  'mod+shift+S': 'strikethrough',
};

export function triggerHotkey(event: React.KeyboardEvent<HTMLDivElement>, editor: Editor) {
  for (const hotkey in HOTKEYS) {
    if (isHotkey(hotkey, event)) {
      event.preventDefault()
      const format = HOTKEYS[hotkey]
      toggleFormat(editor, format)
    }
  }
}