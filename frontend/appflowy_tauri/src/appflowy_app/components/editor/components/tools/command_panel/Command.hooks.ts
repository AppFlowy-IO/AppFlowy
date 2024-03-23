import { useEffect, useState, useCallback, useRef } from 'react';
import { getPanelPosition } from '$app/components/editor/components/tools/command_panel/utils';
import { useSlate } from 'slate-react';
import { PopoverPreventBlurProps } from '$app/components/editor/components/tools/popover';
import { PopoverProps } from '@mui/material/Popover';

import { Editor, Point, Range, Transforms } from 'slate';
import { CustomEditor } from '$app/components/editor/command';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { useSlashState } from '$app/components/editor/stores';

export enum EditorCommand {
  Mention = '@',
  SlashCommand = '/',
}

export const PanelPopoverProps: Partial<PopoverProps> = {
  ...PopoverPreventBlurProps,
  anchorReference: 'anchorPosition',
};

const commands = Object.values(EditorCommand);

export interface PanelProps {
  anchorPosition?: { left: number; top: number; height: number };
  closePanel: (deleteText?: boolean) => void;
  searchText: string;
  openPanel: () => void;
}

export function useCommandPanel() {
  const editor = useSlate();
  const { open: slashOpen, setOpen: setSlashOpen } = useSlashState();
  const [command, setCommand] = useState<EditorCommand | undefined>(undefined);
  const [anchorPosition, setAnchorPosition] = useState<
    | {
        top: number;
        left: number;
        height: number;
      }
    | undefined
  >(undefined);
  const startPoint = useRef<Point>();
  const endPoint = useRef<Point>();
  const open = Boolean(anchorPosition);
  const [searchText, setSearchText] = useState('');

  const closePanel = useCallback(
    (deleteText?: boolean) => {
      if (deleteText && startPoint.current && endPoint.current) {
        const anchor = {
          path: startPoint.current.path,
          offset: startPoint.current.offset > 0 ? startPoint.current.offset - 1 : 0,
        };
        const focus = {
          path: endPoint.current.path,
          offset: endPoint.current.offset,
        };

        if (!Point.equals(anchor, focus)) {
          Transforms.delete(editor, {
            at: {
              anchor,
              focus,
            },
          });
        }
      }

      setSlashOpen(false);
      setCommand(undefined);
      setAnchorPosition(undefined);
      setSearchText('');
    },
    [editor, setSlashOpen]
  );

  const setPosition = useCallback(
    (position?: { left: number; top: number; height: number }) => {
      if (!position) {
        closePanel(false);
        return;
      }

      const nodeEntry = CustomEditor.getBlock(editor);

      if (!nodeEntry) return;

      setAnchorPosition(position);
    },
    [closePanel, editor]
  );

  const openPanel = useCallback(() => {
    const position = getPanelPosition(editor);

    if (position && editor.selection) {
      startPoint.current = Editor.start(editor, editor.selection);
      endPoint.current = Editor.end(editor, editor.selection);
      setPosition(position);
    } else {
      setPosition(undefined);
    }
  }, [editor, setPosition]);

  useEffect(() => {
    if (!slashOpen && command === EditorCommand.SlashCommand) {
      closePanel();
      return;
    }

    if (slashOpen && !open) {
      setCommand(EditorCommand.SlashCommand);
      openPanel();
      return;
    }
  }, [slashOpen, closePanel, command, open, openPanel]);
  /**
   * listen to editor insertText and deleteBackward event
   */
  useEffect(() => {
    const { insertText } = editor;

    /**
     * insertText: when insert char at after space or at start of element, show the panel
     * open condition:
     * 1. open is false
     * 2. current block is not code block
     * 3. current selection is not include root
     * 4. current selection is collapsed
     * 5. insert char is command char
     * 6. before text is empty or end with space
     * --------- start -----------------
     * | - selection point
     * @ - panel char
     * _ - space
     * - - other text
     * -------- open panel ----------------
     * ---_@|---  => insert text is panel char and before text is end with space, open the panel
     * @|---  => insert text is panel char and before text is empty, open the panel
     */
    editor.insertText = (text, opts) => {
      if (open || CustomEditor.isCodeBlock(editor) || CustomEditor.selectionIncludeRoot(editor)) {
        insertText(text, opts);
        return;
      }

      const { selection } = editor;

      const command = commands.find((c) => text.endsWith(c));
      const endOfPanelChar = !!command;

      if (command === EditorCommand.SlashCommand) {
        setSlashOpen(true);
      }

      setCommand(command);
      if (!selection || !endOfPanelChar || !Range.isCollapsed(selection)) {
        insertText(text, opts);
        return;
      }

      const block = CustomEditor.getBlock(editor);
      const path = block ? block[1] : [];
      const { anchor } = selection;
      const beforeText = Editor.string(editor, { anchor, focus: Editor.start(editor, path) }) + text.slice(0, -1);
      // show the panel when insert char at after space or at start of element
      const showPanel = !beforeText || beforeText.endsWith(' ');

      insertText(text, opts);

      if (!showPanel) return;
      openPanel();
    };

    return () => {
      editor.insertText = insertText;
    };
  }, [open, editor, openPanel, setSlashOpen]);

  /**
   * listen to editor onChange event
   */
  useEffect(() => {
    const { onChange } = editor;

    if (!open) return;

    /**
     * onChange: when selection change, update the search text or close the panel
     * --------- start -----------------
     * | - selection point
     * @ - panel char
     * __ - search text
     * - - other text
     * -------- close panel ----------------
     * --|@---  => selection is backward to start point, close the panel
     * ---@__-|---  => selection is forward to end point, close the panel
     * -------- update search text ----------------
     * ---@__|---
     * ---@_|_--- => selection is forward to start point and backward to end point, update the search text
     * ---@|__---
     * --------- end -----------------
     */
    editor.onChange = (...args) => {
      if (!editor.selection || !startPoint.current || !endPoint.current) return;
      onChange(...args);
      const isSelectionChange = editor.operations.every((op) => op.type === 'set_selection');
      const currentPoint = Editor.end(editor, editor.selection);
      const isBackward = currentPoint.offset < startPoint.current.offset;

      if (isBackward) {
        closePanel(false);
        return;
      }

      if (!isSelectionChange) {
        if (currentPoint.offset > endPoint.current?.offset) {
          endPoint.current = currentPoint;
        }

        const text = Editor.string(editor, {
          anchor: startPoint.current,
          focus: endPoint.current,
        });

        setSearchText(text);
      } else {
        const isForward = currentPoint.offset > endPoint.current.offset;

        if (isForward) {
          closePanel(false);
        }
      }
    };

    return () => {
      editor.onChange = onChange;
    };
  }, [open, editor, closePanel]);

  return {
    anchorPosition,
    closePanel,
    searchText,
    openPanel,
    command,
  };
}

export const initialTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'left',
};

export const initialAnchorOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'right',
};
