import { getRangeRect } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import React, { createContext, useState, useCallback, useEffect, useRef } from 'react';
import { BaseRange, Point } from 'slate';
import { ReactEditor } from 'slate-react';
import { TextInsertTextOptions } from 'slate/dist/interfaces/transforms/text';

export enum PanelType {
  Slash = 'slash',
  Mention = 'mention',
  PageReference = 'pageReference',
}

export interface PanelContextType {
  activePanel?: PanelType;
  panelPosition?: { top: number; left: number };
  setActivePanel: (panel: PanelType) => void;
  closePanel: () => void;
  openPanel: (panel: PanelType, position: { top: number; left: number }) => void;
  isPanelOpen: (panel: PanelType) => boolean;
  searchText?: string;
  removeContent: () => void;
}

export const PanelContext = createContext({
  setActivePanel: () => {
    return;
  },
  closePanel: () => {
    return;
  },
  openPanel: () => {
    return;
  },
  removeContent: () => {
    return;
  },
  isPanelOpen: () => false,
} as PanelContextType);

const panelTypeChars = ['/', '@', '+'];

export const PanelProvider = ({ children, editor }: { children: React.ReactNode; editor: ReactEditor }) => {
  const [activePanel, setActivePanel] = useState<PanelType | undefined>(undefined);
  const [panelPosition, setPanelPosition] = useState<{ top: number; left: number } | undefined>(undefined);
  const startSelection = useRef<BaseRange | null>(null);
  const endSelection = useRef<BaseRange | null>(null);
  const [searchText, setSearchText] = useState('');

  const closePanel = useCallback(() => {
    setActivePanel(undefined);
    startSelection.current = null;
    endSelection.current = null;
    setSearchText('');
  }, []);

  const removeContent = useCallback(() => {
    const { selection } = editor;

    if (!selection) return;

    const start = startSelection.current?.anchor;
    const end = endSelection.current?.focus;

    if (!start || !end) return;
    const length = end.offset - start.offset;

    if (length === 0) return;
    editor.delete({
      at: {
        anchor: start,
        focus: end,
      },

    });
  }, [editor]);

  const openPanel = useCallback((panel: PanelType, position: { top: number; left: number }) => {
    setActivePanel(panel);
    setPanelPosition(position);
    const { selection } = editor;

    if (!selection) return;
    startSelection.current = editor.selection;
    endSelection.current = editor.selection;
  }, [editor]);

  const isPanelOpen = useCallback((panel: PanelType) => {
    return activePanel === panel;
  }, [activePanel]);

  useEffect(() => {
    const { insertText } = editor;

    editor.insertText = (text: string, options?: TextInsertTextOptions) => {
      insertText(text, options);
      const { selection } = editor;

      if (!selection) return;
      if (activePanel !== undefined) return;

      if (panelTypeChars.includes(text)) {
        const position = getRangeRect();

        if (!position) return;

        const panelType = { '/': PanelType.Slash, '+': PanelType.PageReference, '@': PanelType.Mention }[text];

        if (!panelType) return;

        openPanel(panelType, { top: position.top, left: position.left });

        startSelection.current = {
          anchor: {
            path: selection.anchor.path,
            offset: selection.anchor.offset - 1,
          },
          focus: selection.focus,
        };
        endSelection.current = editor.selection;
        return;
      }

      const rangeText = editor.string({
        anchor: {
          path: selection.anchor.path,
          offset: selection.anchor.offset - 2,
        },
        focus: selection.focus,
      });

      if (rangeText === '[[') {
        const position = getRangeRect();

        if (!position) return;

        openPanel(PanelType.PageReference, { top: position.top, left: position.left });
        startSelection.current = {
          anchor: {
            path: selection.anchor.path,
            offset: selection.anchor.offset - 2,
          },
          focus: selection.focus,
        };
        endSelection.current = editor.selection;
      }
    };

    return () => {
      editor.insertText = insertText;
    };
  }, [activePanel, editor, openPanel]);

  useEffect(() => {
    const { onChange } = editor;

    if (!activePanel) return;

    editor.onChange = () => {
      onChange();
      const { selection } = editor;
      let start = startSelection.current?.focus;

      if (!selection) return;

      if (!start) {
        startSelection.current = selection;
        start = selection.anchor;
      }

      const text = editor.string({
        anchor: start,
        focus: selection.focus,
      });

      if (Point.isBefore(selection.anchor, start)) {
        closePanel();
        return;
      }

      endSelection.current = selection;

      setSearchText(text);
    };

    return () => {
      editor.onChange = onChange;
    };

  }, [editor, activePanel, closePanel]);

  const open = activePanel !== undefined;

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!open) return;
      const { key } = e;

      switch (key) {
        case 'Escape':
          e.stopPropagation();
          closePanel();
          break;
        case 'ArrowLeft':
        case 'ArrowRight': {
          e.preventDefault();
          break;
        }

        case 'Backspace': {
          const { selection } = editor;

          if (!selection || !startSelection.current) return;
          const text = editor.string({
            anchor: startSelection.current.focus,
            focus: selection?.focus,
          });

          if (text === '') {
            closePanel();
          }

          break;
        }

        default:
          break;
      }

    };

    const slateDom = ReactEditor.toDOMNode(editor, editor);

    slateDom.addEventListener('keydown', handleKeyDown);

    return () => {
      slateDom.removeEventListener('keydown', handleKeyDown);
    };
  }, [closePanel, editor, open]);

  return (
    <PanelContext.Provider
      value={{
        activePanel,
        setActivePanel,
        closePanel,
        openPanel,
        isPanelOpen,
        panelPosition,
        searchText,
        removeContent,
      }}
    >
      {children}
    </PanelContext.Provider>
  );
};

