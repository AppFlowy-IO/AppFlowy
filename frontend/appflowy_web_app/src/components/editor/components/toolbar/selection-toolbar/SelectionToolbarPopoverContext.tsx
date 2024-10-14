import { useToolbarPopover } from './SelectionToolbar.hooks';
import React, { createContext, useContext, ReactNode } from 'react';
import { Popover } from '@/components/_shared/popover';
import { YjsEditor } from '@/application/slate-yjs';
import { useSlateStatic } from 'slate-react';

interface SelectionToolbarPopoverContextType {
  open: boolean;
  openPopover: () => void;
  closePopover: () => void;
}

const SelectionToolbarPopoverContext = createContext<SelectionToolbarPopoverContextType | null>(null);

export function useSelectionToolbarPopoverContext () {
  const context = useContext(SelectionToolbarPopoverContext);

  if (!context) {
    throw new Error('useSelectionToolbarPopoverContext must be used within a SelectionToolbarPopoverProvider');
  }

  return context;
}

interface SelectionToolbarPopoverProviderProps {
  children: ReactNode;
  popoverContent: React.ReactNode;
}

export function SelectionToolbarPopoverProvider ({ children, popoverContent }: SelectionToolbarPopoverProviderProps) {
  const editor = useSlateStatic() as YjsEditor;
  const {
    open,
    anchorPosition,
    handleClose,
    openPopover,
  } = useToolbarPopover(editor);

  return (
    <SelectionToolbarPopoverContext.Provider value={{ open, openPopover, closePopover: handleClose }}>
      {children}
      {open && (
        <Popover
          onMouseDown={e => {
            e.preventDefault();
            e.stopPropagation();
          }}
          onMouseUp={e => {
            e.stopPropagation();
          }}
          disableRestoreFocus={false}
          open={open}
          onClose={handleClose}
          anchorPosition={anchorPosition}
          anchorReference={'anchorPosition'}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'center',
          }}
        >
          {popoverContent}
        </Popover>
      )}
    </SelectionToolbarPopoverContext.Provider>
  );
}