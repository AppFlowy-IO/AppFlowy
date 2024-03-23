import { ReactEditor } from 'slate-react';
import { useCallback, KeyboardEvent } from 'react';
import { EditorMarkFormat, EditorNodeType, ToggleListNode } from '$app/application/document/document.types';
import { getBlock } from '$app/components/editor/plugins/utils';
import { SOFT_BREAK_TYPES } from '$app/components/editor/plugins/constants';
import { CustomEditor } from '$app/components/editor/command';
import { createHotkey, HOT_KEY_NAME } from '$app/utils/hotkeys';
import { openUrl } from '$app/utils/open_url';
import { Range } from 'slate';
import { readText } from '@tauri-apps/api/clipboard';
import { useDecorateDispatch } from '$app/components/editor/stores';

function getScrollContainer(editor: ReactEditor) {
  const editorDom = ReactEditor.toDOMNode(editor, editor);

  return editorDom.closest('.appflowy-scroll-container') as HTMLDivElement;
}

export function useShortcuts(editor: ReactEditor) {
  const { add: addDecorate } = useDecorateDispatch();

  const formatLink = useCallback(() => {
    const { selection } = editor;

    if (!selection || Range.isCollapsed(selection)) return;

    const isIncludeRoot = CustomEditor.selectionIncludeRoot(editor);

    if (isIncludeRoot) return;

    const isActivatedInline = CustomEditor.isInlineActive(editor);

    if (isActivatedInline) return;

    addDecorate({
      range: selection,
      class_name: 'bg-content-blue-100 rounded',
      type: 'link',
    });
  }, [addDecorate, editor]);

  const onKeyDown = useCallback(
    (e: KeyboardEvent<HTMLDivElement>) => {
      const event = e.nativeEvent;
      const hasEditableTarget = ReactEditor.hasEditableTarget(editor, event.target);

      if (!hasEditableTarget) return;

      const node = getBlock(editor);

      const { selection } = editor;
      const isExpanded = selection && Range.isExpanded(selection);

      switch (true) {
        /**
         * Select all: Mod+A
         * Default behavior: Select all text in the editor
         * Special case for select all in code block: Only select all text in code block
         */
        case createHotkey(HOT_KEY_NAME.SELECT_ALL)(event):
          if (node && node.type === EditorNodeType.CodeBlock) {
            e.preventDefault();
            const path = ReactEditor.findPath(editor, node);

            editor.select(path);
          }

          break;
        /**
         * Escape: Esc
         * Default behavior: Deselect editor
         */
        case createHotkey(HOT_KEY_NAME.ESCAPE)(event):
          editor.deselect();
          break;
        /**
         * Indent block: Tab
         * Default behavior: Indent block
         */
        case createHotkey(HOT_KEY_NAME.INDENT_BLOCK)(event):
          e.preventDefault();
          if (SOFT_BREAK_TYPES.includes(node?.type as EditorNodeType)) {
            editor.insertText('\t');
            break;
          }

          CustomEditor.tabForward(editor);
          break;
        /**
         * Outdent block: Shift+Tab
         * Default behavior: Outdent block
         */
        case createHotkey(HOT_KEY_NAME.OUTDENT_BLOCK)(event):
          e.preventDefault();
          CustomEditor.tabBackward(editor);
          break;
        /**
         * Split block: Enter
         * Default behavior: Split block
         * Special case for soft break types: Insert \n
         */
        case createHotkey(HOT_KEY_NAME.SPLIT_BLOCK)(event):
          if (SOFT_BREAK_TYPES.includes(node?.type as EditorNodeType)) {
            e.preventDefault();
            editor.insertText('\n');
          }

          break;
        /**
         * Insert soft break: Shift+Enter
         * Default behavior: Insert \n
         * Special case for soft break types: Split block
         */
        case createHotkey(HOT_KEY_NAME.INSERT_SOFT_BREAK)(event):
          e.preventDefault();
          if (node && SOFT_BREAK_TYPES.includes(node.type as EditorNodeType)) {
            editor.splitNodes({
              always: true,
            });
          } else {
            editor.insertText('\n');
          }

          break;
        /**
         * Toggle todo: Shift+Enter
         * Default behavior: Toggle todo
         * Special case for toggle list block: Toggle collapse
         */
        case createHotkey(HOT_KEY_NAME.TOGGLE_TODO)(event):
        case createHotkey(HOT_KEY_NAME.TOGGLE_COLLAPSE)(event):
          e.preventDefault();
          if (node && node.type === EditorNodeType.ToggleListBlock) {
            CustomEditor.toggleToggleList(editor, node as ToggleListNode);
          } else {
            CustomEditor.toggleTodo(editor);
          }

          break;
        /**
         * Backspace: Backspace / Shift+Backspace
         * Default behavior: Delete backward
         */
        case createHotkey(HOT_KEY_NAME.BACKSPACE)(event):
          e.stopPropagation();
          break;
        /**
         * Open link: Alt + enter
         * Default behavior: Open one link in selection
         */
        case createHotkey(HOT_KEY_NAME.OPEN_LINK)(event): {
          if (!isExpanded) break;
          e.preventDefault();
          const links = CustomEditor.getLinks(editor);

          if (links.length === 0) break;
          openUrl(links[0]);
          break;
        }

        /**
         * Open links: Alt + Shift + enter
         * Default behavior: Open all links in selection
         */
        case createHotkey(HOT_KEY_NAME.OPEN_LINKS)(event): {
          if (!isExpanded) break;
          e.preventDefault();
          const links = CustomEditor.getLinks(editor);

          if (links.length === 0) break;
          links.forEach((link) => openUrl(link));
          break;
        }

        /**
         * Extend line backward: Opt + Shift + right
         * Default behavior: Extend line backward
         */
        case createHotkey(HOT_KEY_NAME.EXTEND_LINE_BACKWARD)(event):
          e.preventDefault();
          CustomEditor.extendLineBackward(editor);
          break;
        /**
         * Extend line forward: Opt + Shift + left
         */
        case createHotkey(HOT_KEY_NAME.EXTEND_LINE_FORWARD)(event):
          e.preventDefault();
          CustomEditor.extendLineForward(editor);
          break;

        /**
         * Paste: Mod + Shift + V
         * Default behavior: Paste plain text
         */
        case createHotkey(HOT_KEY_NAME.PASTE_PLAIN_TEXT)(event):
          e.preventDefault();
          void (async () => {
            const text = await readText();

            if (!text) return;
            CustomEditor.insertPlainText(editor, text);
          })();

          break;
        /**
         * Highlight: Mod + Shift + H
         * Default behavior: Highlight selected text
         */
        case createHotkey(HOT_KEY_NAME.HIGH_LIGHT)(event):
          e.preventDefault();
          CustomEditor.highlight(editor);
          break;
        /**
         * Extend document backward: Mod + Shift + Up
         * Don't prevent default behavior
         * Default behavior: Extend document backward
         */
        case createHotkey(HOT_KEY_NAME.EXTEND_DOCUMENT_BACKWARD)(event):
          editor.collapse({ edge: 'start' });
          break;
        /**
         * Extend document forward: Mod + Shift + Down
         * Don't prevent default behavior
         * Default behavior: Extend document forward
         */
        case createHotkey(HOT_KEY_NAME.EXTEND_DOCUMENT_FORWARD)(event):
          editor.collapse({ edge: 'end' });
          break;

        /**
         * Scroll to top: Home
         * Default behavior: Scroll to top
         */
        case createHotkey(HOT_KEY_NAME.SCROLL_TO_TOP)(event): {
          const scrollContainer = getScrollContainer(editor);

          scrollContainer.scrollTo({
            top: 0,
          });
          break;
        }

        /**
         * Scroll to bottom: End
         * Default behavior: Scroll to bottom
         */
        case createHotkey(HOT_KEY_NAME.SCROLL_TO_BOTTOM)(event): {
          const scrollContainer = getScrollContainer(editor);

          scrollContainer.scrollTo({
            top: scrollContainer.scrollHeight,
          });
          break;
        }

        /**
         * Align left: Control + Shift + L
         * Default behavior: Align left
         */
        case createHotkey(HOT_KEY_NAME.ALIGN_LEFT)(event):
          e.preventDefault();
          CustomEditor.toggleAlign(editor, 'left');
          break;
        /**
         * Align center: Control + Shift + E
         */
        case createHotkey(HOT_KEY_NAME.ALIGN_CENTER)(event):
          e.preventDefault();
          CustomEditor.toggleAlign(editor, 'center');
          break;
        /**
         * Align right: Control + Shift + R
         */
        case createHotkey(HOT_KEY_NAME.ALIGN_RIGHT)(event):
          e.preventDefault();
          CustomEditor.toggleAlign(editor, 'right');
          break;
        /**
         * Bold: Mod + B
         */
        case createHotkey(HOT_KEY_NAME.BOLD)(event):
          e.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Bold,
            value: true,
          });
          break;
        /**
         * Italic: Mod + I
         */
        case createHotkey(HOT_KEY_NAME.ITALIC)(event):
          e.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Italic,
            value: true,
          });
          break;
        /**
         * Underline: Mod + U
         */
        case createHotkey(HOT_KEY_NAME.UNDERLINE)(event):
          e.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Underline,
            value: true,
          });
          break;
        /**
         * Strikethrough: Mod + Shift + S / Mod + Shift + X
         */
        case createHotkey(HOT_KEY_NAME.STRIKETHROUGH)(event):
          e.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.StrikeThrough,
            value: true,
          });
          break;
        /**
         * Code: Mod + E
         */
        case createHotkey(HOT_KEY_NAME.CODE)(event):
          e.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Code,
            value: true,
          });
          break;
        /**
         * Format link: Mod + K
         */
        case createHotkey(HOT_KEY_NAME.FORMAT_LINK)(event):
          formatLink();
          break;

        case createHotkey(HOT_KEY_NAME.FIND_REPLACE)(event):
          console.log('find replace');
          break;

        default:
          break;
      }
    },
    [formatLink, editor]
  );

  return {
    onKeyDown,
  };
}
