import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { SOFT_BREAK_TYPES } from '@/application/slate-yjs/command/const';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { AlignType, BlockType } from '@/application/types';
import { useEditorContext } from '@/components/editor/EditorContext';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { openUrl } from '@/utils/url';
import { KeyboardEvent, useCallback } from 'react';
import { Editor, Text, Range, Transforms, BasePoint, Path } from 'slate';
import { ReactEditor, useReadOnly } from 'slate-react';
import smoothScrollIntoViewIfNeeded from 'smooth-scroll-into-view-if-needed';

export function useShortcuts (editor: ReactEditor) {
  const yjsEditor = editor as YjsEditor;
  const { viewId } = useEditorContext();
  const readOnly = useReadOnly();

  const focusedFocusableElement = useCallback((toStart?: boolean) => {
    if (readOnly) return;
    const title = document.getElementById(`editor-title-${viewId}`);

    if (!title) return;

    const selection = window.getSelection();
    const range = document.createRange();

    const textNode = title.childNodes[0] as Node;

    range.setStart(textNode, toStart ? 0 : (textNode?.textContent?.length || 0));
    selection?.removeAllRanges();
    selection?.addRange(range);
  }, [readOnly, viewId]);

  const onKeyDown = useCallback((event: KeyboardEvent<HTMLDivElement>) => {
    const e = event.nativeEvent;
    const { selection } = editor;

    // Add more cases here for general shortcuts
    switch (true) {
      /**
       * Escape: Esc
       * Default behavior: Deselect editor
       */
      case createHotkey(HOT_KEY_NAME.ESCAPE)(e):
        editor.deselect();
        break;

      default:
        break;
    }

    if (selection && Range.isCollapsed(selection)) {
      switch (true) {
        case createHotkey(HOT_KEY_NAME.UP)(e): {
          const path = editor.start(selection).path;

          if (Path.isAncestor([0, 0], path)) {
            e.preventDefault();
            focusedFocusableElement(false);
            break;
          }

          const before = Editor.before(editor, selection, { unit: 'offset' });
          const beforeText = findInlineTextNode(editor, before);

          if (before && beforeText) {
            e.preventDefault();
            Transforms.move(editor, { unit: 'line', reverse: true, distance: 2 });
            return;
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.BACKSPACE)(e): {
          const [node] = getBlockEntry(yjsEditor);
          const type = node.type as BlockType;

          if (type !== BlockType.Paragraph) {
            break;
          }

          const path = editor.start(selection).path;

          const before = Editor.before(editor, selection, { unit: 'offset' });

          if (!before && Path.isAncestor([0, 0], path)) {
            focusedFocusableElement(true);
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.LEFT)(e): {
          const path = editor.start(selection).path;
          const before = Editor.before(editor, selection, { unit: 'offset' });

          if (!before && Path.isAncestor([0, 0], path)) {
            focusedFocusableElement(false);
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.DOWN)(e): {
          const after = Editor.after(editor, selection, { unit: 'offset' });
          const afterText = findInlineTextNode(editor, after);

          if (afterText) {
            e.preventDefault();
            Transforms.move(editor, { unit: 'line', distance: 2 });
            return;
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.OPEN_LINK)(e): {
          event.preventDefault();
          const marks = CustomEditor.getAllMarks(editor);

          const link = marks.find((mark) => !!mark[EditorMarkFormat.Href])?.[EditorMarkFormat.Href];

          if (link) {
            void openUrl(link, '_blank');
            return;
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.DELETE_LEFT_SENTENCE)(e): {
          event.preventDefault();
          const focus = editor.start(selection);
          const anchor = Editor.before(editor, focus, { unit: 'line' });

          if (anchor) {
            editor.delete({
              at: {
                anchor,
                focus,
              },
            });
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.DELETE_LEFT_WORD)(e): {
          event.preventDefault();
          const focus = editor.start(selection);
          const anchor = Editor.before(editor, focus, { unit: 'word' });

          if (anchor) {
            editor.delete({
              at: {
                anchor,
                focus,
              },
            });
          }

          break;
        }

        case createHotkey(HOT_KEY_NAME.DELETE_RIGHT_WORD)(e): {
          event.preventDefault();
          const focus = editor.start(selection);
          const anchor = Editor.after(editor, focus, { unit: 'word' });

          if (anchor) {
            editor.delete({
              at: {
                anchor,
                focus,
              },
            });
          }

          break;
        }

        default:
          break;
      }

    }

    // Do not process shortcuts if editor is read-only or no selection
    if (readOnly || !selection) return;
    const [point] = editor.edges(selection);
    const node = getBlockEntry(yjsEditor, point);

    // Add more cases here for editing shortcuts
    switch (!readOnly) {
      /**
       * Select all: Mod+A
       * Default behavior: Select all text in the editor
       * Special case for select all in code block: Only select all text in code block
       */
      case createHotkey(HOT_KEY_NAME.SELECT_ALL)(e):
        if (node && node[0].type === BlockType.CodeBlock) {
          event.preventDefault();
          editor.select(node[1]);
        }

        break;
      /**
       * Indent block: Tab
       * Default behavior: Indent block
       */
      case createHotkey(HOT_KEY_NAME.INDENT_BLOCK)(e):
        event.preventDefault();

        if (SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          editor.insertText('\t');
          break;
        }

        CustomEditor.tabEvent(yjsEditor, e);
        break;
      /**
       * Outdent block: Shift+Tab
       * Default behavior: Outdent block
       */
      case createHotkey(HOT_KEY_NAME.OUTDENT_BLOCK)(e):
        event.preventDefault();

        if (SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          editor.deleteBackward('character');
          break;
        }

        CustomEditor.tabEvent(yjsEditor, e);
        break;
      /**
       * Split block: Enter
       * Default behavior: Split block
       * Special case for soft break types: Insert \n
       */
      case createHotkey(HOT_KEY_NAME.SPLIT_BLOCK)(e):
        if (SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          event.preventDefault();
          editor.insertText('\n');
        }

        break;
      /**
       * Insert soft break: Shift+Enter
       * Default behavior: Insert \n
       * Special case for soft break types: Split block
       */
      case createHotkey(HOT_KEY_NAME.INSERT_SOFT_BREAK)(e):
        event.preventDefault();
        if (node && SOFT_BREAK_TYPES.includes(node[0]?.type as BlockType)) {
          editor.insertBreak();
        } else {
          editor.insertText('\n');
        }

        break;
      /**
       * Toggle todo: Mod+Enter
       * Default behavior: Toggle todo
       * Special case for toggle list block: Toggle collapse
       */
      case createHotkey(HOT_KEY_NAME.TOGGLE_TODO)(e):
      case createHotkey(HOT_KEY_NAME.TOGGLE_COLLAPSE)(e):
        event.preventDefault();

        if (node[0].type === BlockType.ToggleListBlock) {
          CustomEditor.toggleToggleList(yjsEditor, node[0].blockId as string);
        } else if (node[0].type === BlockType.TodoListBlock) {
          CustomEditor.toggleTodoList(yjsEditor, node[0].blockId as string, false);
        }

        break;

      /**
       * Open link: Opt + SHIFT + Enter
       */
      case createHotkey(HOT_KEY_NAME.OPEN_LINKS)(e): {
        event.preventDefault();
        const marks = CustomEditor.getAllMarks(editor);
        const links = marks.map((mark) => mark[EditorMarkFormat.Href]).filter(Boolean);

        if (links.length === 0) break;
        links.forEach((link) => {
          if (link) void openUrl(link, '_blank');
        });
        break;
      }

      /**
       * Extend document backward: Mod + Shift + Up
       */
      case createHotkey(HOT_KEY_NAME.EXTEND_DOCUMENT_BACKWARD)(e): {

        event.preventDefault();
        const { selection } = editor;

        if (!selection) return;
        const focus = editor.start(selection);
        const anchor = editor.start([0, 0]);

        editor.select({
          anchor,
          focus,
        });
        break;
      }

      /**
       * Extend document forward: Mod + Shift + Down
       */
      case createHotkey(HOT_KEY_NAME.EXTEND_DOCUMENT_FORWARD)(e): {

        event.preventDefault();
        const { selection } = editor;

        if (!selection) return;
        const anchor = editor.end(selection);
        const focus = editor.end([editor.children.length - 1, 0]);

        editor.select({
          anchor,
          focus,
        });
        break;
      }

      /**
       * Extend line backward: Opt + Shift + Left
       */
      case createHotkey(HOT_KEY_NAME.EXTEND_LINE_BACKWARD)(e):
        event.preventDefault();
        Transforms.move(editor, {
          unit: 'word',
          reverse: true,
        });
        break;
      /**
       * Extend line forward: Opt + Shift + Right
       */
      case createHotkey(HOT_KEY_NAME.EXTEND_LINE_FORWARD)(e):
        event.preventDefault();
        Transforms.move(editor, { unit: 'word' });
        break;
      /**
       * Paste Text: Mod + Shift + V
       */
      case createHotkey(HOT_KEY_NAME.PASTE_PLAIN_TEXT)(e):
        event.preventDefault();
        void navigator.clipboard.readText().then((text) => {
          CustomEditor.pastedText(yjsEditor, text);
        });
        break;
      /**
       * Scroll to top: Home
       */
      case createHotkey(HOT_KEY_NAME.SCROLL_TO_TOP)(e): {
        event.preventDefault();
        const dom = ReactEditor.toDOMNode(editor, editor);

        void smoothScrollIntoViewIfNeeded(dom, {
          behavior: 'smooth',
          block: 'start',
        });
        break;
      }

      /**
       * Scroll to bottom: End
       */
      case createHotkey(HOT_KEY_NAME.SCROLL_TO_BOTTOM)(e): {
        event.preventDefault();
        const dom = ReactEditor.toDOMNode(editor, editor);

        void smoothScrollIntoViewIfNeeded(dom, {
          behavior: 'smooth',
          block: 'end',
        });

        break;
      }

      /**
       * Align left: Control + Shift + L
       */
      case createHotkey(HOT_KEY_NAME.ALIGN_LEFT)(e): {

        event.preventDefault();

        const blockId = node[0].blockId as string;

        CustomEditor.setBlockData(yjsEditor, blockId, {
          align: AlignType.Left,
        });
        break;
      }

      /**
       * Align center: Control + Shift + E
       */
      case createHotkey(HOT_KEY_NAME.ALIGN_CENTER)(e): {

        event.preventDefault();

        const blockId = node[0].blockId as string;

        CustomEditor.setBlockData(yjsEditor, blockId, {
          align: AlignType.Center,
        });
        break;
      }

      /**
       * Align right: Control + Shift + R
       */
      case createHotkey(HOT_KEY_NAME.ALIGN_RIGHT)(e): {

        event.preventDefault();

        const blockId = node[0].blockId as string;

        CustomEditor.setBlockData(yjsEditor, blockId, {
          align: AlignType.Right,
        });
        break;
      }

      case createHotkey(HOT_KEY_NAME.MOVE_CURSOR_TO_BOTTOM)(e): {
        event.preventDefault();
        const point = Editor.end(editor, [editor.children.length - 1, 0]);

        if (!point) return;
        const dom = ReactEditor.toDOMNode(editor, editor);

        void smoothScrollIntoViewIfNeeded(dom, {
          behavior: 'smooth',
          block: 'end',
        });
        editor.select({
          anchor: point,
          focus: point,
        });

        break;
      }

      case createHotkey(HOT_KEY_NAME.MOVE_CURSOR_TO_TOP)(e): {
        event.preventDefault();
        const point = Editor.start(editor, [0, 0]);

        if (!point) return;
        const dom = ReactEditor.toDOMNode(editor, editor);

        void smoothScrollIntoViewIfNeeded(dom, {
          behavior: 'smooth',
          block: 'start',
        });
        editor.select({
          anchor: point,
          focus: point,
        });

        break;
      }

      default:
        break;
    }
  }, [focusedFocusableElement, editor, yjsEditor, readOnly]);

  return {
    onKeyDown,
  };
}

function findInlineTextNode (editor: Editor, point?: BasePoint) {
  const [node] = editor.nodes({
    at: point,
    match: (n) => {
      return !Editor.isEditor(n) && Text.isText(n) && Boolean(n.mention || n.formula);
    },
  });

  return node;
}