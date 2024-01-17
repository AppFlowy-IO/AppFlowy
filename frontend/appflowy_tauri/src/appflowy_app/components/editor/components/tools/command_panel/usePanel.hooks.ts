import { useEffect, RefObject, useState, useCallback, useRef } from 'react';
import { getPanelPosition } from '$app/components/editor/components/tools/command_panel/utils';
import { ReactEditor, useSlate } from 'slate-react';
import { PopoverPreventBlurProps } from '$app/components/editor/components/tools/popover';
import { PopoverProps } from '@mui/material/Popover';
import { commandPanelShowProperty } from '$app/components/editor/components/editor/shortcuts/withCommandShortcuts';
import { Editor, Point, Transforms } from 'slate';
import { CustomEditor } from '$app/components/editor/command';

export const PanelPopoverProps: Partial<PopoverProps> = {
  ...PopoverPreventBlurProps,
  onMouseUp: (e) => e.stopPropagation(),
  transformOrigin: {
    vertical: -28,
    horizontal: 'left',
  },
  anchorReference: 'anchorPosition',
};

export function usePanel(ref: RefObject<HTMLDivElement | null>) {
  const editor = useSlate();
  const [anchorPosition, setAnchorPosition] = useState<
    | {
        top: number;
        left: number;
      }
    | undefined
  >(undefined);
  const startPoint = useRef<Point>();
  const endPoint = useRef<Point>();
  const open = Boolean(anchorPosition);
  const [searchText, setSearchText] = useState('');

  const closePanel = useCallback(
    (deleteText?: boolean) => {
      ref.current?.classList.remove(commandPanelShowProperty);

      if (deleteText && startPoint.current && endPoint.current) {
        const anchor = {
          path: startPoint.current.path,
          offset: startPoint.current.offset - 1,
        };
        const focus = {
          path: endPoint.current.path,
          offset: endPoint.current.offset,
        };

        Transforms.delete(editor, {
          at: {
            anchor,
            focus,
          },
        });
      }

      setAnchorPosition(undefined);
      setSearchText('');
    },
    [editor, ref]
  );

  const setPosition = useCallback(
    (position?: { left: number; top: number }) => {
      if (!position) {
        closePanel(false);
        return;
      }

      const nodeEntry = CustomEditor.getBlock(editor);

      if (!nodeEntry) return;

      setAnchorPosition({
        top: position.top,
        left: position.left,
      });
    },
    [closePanel, editor]
  );

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    let prevState = el.classList.contains(commandPanelShowProperty);
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        const { target } = mutation;

        if (mutation.attributeName === 'class') {
          const currentState = (target as HTMLElement).classList.contains(commandPanelShowProperty);

          if (prevState !== currentState) {
            prevState = currentState;
            if (currentState) {
              const position = getPanelPosition(editor);

              if (position && editor.selection) {
                startPoint.current = Editor.start(editor, editor.selection);
                endPoint.current = Editor.end(editor, editor.selection);
                setPosition(position);
              } else {
                setPosition(undefined);
              }
            } else {
              setPosition(undefined);
            }
          }
        }
      });
    });

    observer.observe(el, { attributes: true });

    return () => {
      observer.disconnect();
    };
  }, [setPosition, editor, ref]);

  useEffect(() => {
    const { onChange } = editor;

    if (open) {
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
    } else {
      editor.onChange = onChange;
    }

    return () => {
      editor.onChange = onChange;
    };
  }, [open, editor, closePanel]);

  return {
    anchorPosition,
    closePanel,
    searchText,
  };
}

export function useKeyDown({
  scrollRef: ref,
  options,
  panelOpen: open,
  setSelectedKey,
  selectedKey,
  closePanel,
}: {
  panelOpen: boolean;
  selectedKey?: string | number;
  setSelectedKey: (key?: string | number) => void;
  closePanel: (deleteText?: boolean) => void;
  scrollRef: RefObject<HTMLDivElement | null>;
  options: {
    key: string | number;
    label: string;
    options: { key: string | number; label: string; onClick: () => void }[];
  }[];
}) {
  const editor = useSlate();
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      const flattenOptions = options.flatMap((group) => group.options);

      const index = flattenOptions.findIndex((option) => option.key === selectedKey);
      const option = flattenOptions[index];
      const nextIndex = (index + 1) % flattenOptions.length;
      const prevIndex = (index - 1 + flattenOptions.length) % flattenOptions.length;

      switch (e.key) {
        case 'Escape':
          e.preventDefault();
          closePanel(false);
          break;
        case 'ArrowDown': {
          e.preventDefault();
          const nextOption = flattenOptions[nextIndex].key;
          const dom = ref.current?.querySelector(`[data-type="${nextOption}"]`);

          setSelectedKey(nextOption);

          dom?.scrollIntoView({
            behavior: 'smooth',
            block: 'end',
          });
          break;
        }

        case 'ArrowUp': {
          e.preventDefault();
          const prevOption = flattenOptions[prevIndex].key;
          const prevDom = ref.current?.querySelector(`[data-type="${prevOption}"]`);

          setSelectedKey(prevOption);
          prevDom?.scrollIntoView({
            behavior: 'smooth',
            block: 'end',
          });
          break;
        }

        case 'Enter':
        case 'Tab':
          e.preventDefault();
          option.onClick();
          break;
      }
    },
    [selectedKey, options, closePanel, ref, setSelectedKey]
  );

  useEffect(() => {
    const slateDom = ReactEditor.toDOMNode(editor, editor);

    if (open) {
      slateDom.addEventListener('keydown', handleKeyDown);
    } else {
      slateDom.removeEventListener('keydown', handleKeyDown);
    }

    return () => {
      slateDom.removeEventListener('keydown', handleKeyDown);
    };
  }, [editor, handleKeyDown, open]);
}
