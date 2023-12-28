import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { ReactEditor, useSlate } from 'slate-react';
import IconButton from '@mui/material/IconButton';
import { Range } from 'slate';
import {
  SelectionAction,
  useBlockFormatActions,
  useSelectionMarkFormatActions,
  useSelectionStyleFormatActions,
  useSelectionTextFormatActions,
} from '$app/components/editor/components/tools/selection_toolbar/SelectionActions.hooks';
import Popover from '@mui/material/Popover';
import { EditorStyleFormat } from '$app/application/document/document.types';
import { PopoverPreventBlurProps } from '$app/components/editor/components/tools/popover';
import { Tooltip } from '@mui/material';
import { CustomEditor } from '$app/components/editor/command';

function SelectionActions({
  toolbarVisible,
  storeSelection,
  restoreSelection,
}: {
  toolbarVisible: boolean;
  storeSelection: () => void;
  restoreSelection: () => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const editor = useSlate() as ReactEditor;
  const [anchorEl, setAnchorEl] = useState<HTMLButtonElement | null>(null);
  const [menuType, setMenuType] = useState<EditorStyleFormat | null>(null);
  const open = Boolean(anchorEl);
  const handlePopoverOpen = useCallback((format: EditorStyleFormat, target: HTMLButtonElement) => {
    setAnchorEl(target);
    setMenuType(format);
  }, []);

  const handleFocus = useCallback(() => {
    storeSelection();
  }, [storeSelection]);

  const handleBlur = useCallback(() => {
    restoreSelection();
  }, [restoreSelection]);

  const handlePopoverClose = useCallback(() => {
    setAnchorEl(null);
    setMenuType(null);
    handleBlur();
  }, [handleBlur]);

  const [isMultiple, setIsMultiple] = useState(false);
  const getIsMultiple = useCallback(() => {
    if (!editor.selection) return false;
    const selection = editor.selection;
    const start = selection.anchor;
    const end = selection.focus;

    if (!start || !end) return false;

    if (!Range.isExpanded(selection)) return false;

    const startNode = CustomEditor.getBlock(editor, start);

    const endNode = CustomEditor.getBlock(editor, end);

    return Boolean(startNode && endNode && startNode[0].blockId !== endNode[0].blockId);
  }, [editor]);

  useEffect(() => {
    if (toolbarVisible) {
      setIsMultiple(getIsMultiple());
    } else {
      setIsMultiple(false);
    }
  }, [editor, getIsMultiple, toolbarVisible]);

  const markOptions = useSelectionMarkFormatActions(editor);
  const textOptions = useSelectionTextFormatActions(editor);
  const blockOptions = useBlockFormatActions(editor);
  const { options: styleOptions, subMenu: styleSubMenu } = useSelectionStyleFormatActions(editor, {
    onPopoverOpen: handlePopoverOpen,
    onPopoverClose: handlePopoverClose,
    onFocus: handleFocus,
    onBlur: handleBlur,
  });

  const subMenu = useMemo(() => {
    if (!menuType) return null;

    return styleSubMenu(menuType);
  }, [menuType, styleSubMenu]);

  const group = useMemo(() => {
    const base = [markOptions, styleOptions];

    if (isMultiple) {
      const filter = (option: SelectionAction) => {
        return !option.alwaysInSingleLine;
      };

      return [markOptions.filter(filter), styleOptions.filter(filter)];
    }

    return [textOptions, ...base, blockOptions];
  }, [markOptions, styleOptions, isMultiple, textOptions, blockOptions]);

  useEffect(() => {
    if (!toolbarVisible) {
      handlePopoverClose();
    }
  }, [toolbarVisible, handlePopoverClose]);

  return (
    <div ref={ref} className={'flex w-fit flex-grow items-center'}>
      {group.map((item, index) => {
        return (
          <div key={index} className={index > 0 ? 'border-l border-gray-500' : ''}>
            {item.map((action) => {
              const { format, Icon, text, onClick, isActive } = action;

              const isActivated = isActive();

              return (
                <Tooltip placement={'top'} title={text} key={format}>
                  <IconButton
                    onClick={onClick}
                    size={'small'}
                    className={`bg-transparent px-1.5 py-0 text-bg-body hover:bg-transparent`}
                  >
                    <Icon
                      style={{
                        color: isActivated ? 'var(--fill-default)' : undefined,
                      }}
                      className={'h-4 w-4 text-lg text-bg-body hover:text-fill-hover'}
                    />
                  </IconButton>
                </Tooltip>
              );
            })}
          </div>
        );
      })}
      {open && (
        <Popover
          {...PopoverPreventBlurProps}
          anchorEl={anchorEl}
          open={open}
          onClose={handlePopoverClose}
          anchorOrigin={{
            vertical: 30,
            horizontal: 'left',
          }}
          onMouseUp={(e) => {
            // prevent editor blur
            e.stopPropagation();
          }}
        >
          {subMenu}
        </Popover>
      )}
    </div>
  );
}

export default SelectionActions;
