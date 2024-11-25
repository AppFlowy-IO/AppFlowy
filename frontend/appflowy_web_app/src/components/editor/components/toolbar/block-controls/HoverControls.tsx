import { YjsEditor } from '@/application/slate-yjs';
import {
  filterValidNodes,
  findSlateEntryByBlockId,
  getSelectedPaths,
  isSameDepth,
} from '@/application/slate-yjs/utils/slateUtils';
import ControlsMenu from '@/components/editor/components/toolbar/block-controls/ControlsMenu';
import { useHoverControls } from '@/components/editor/components/toolbar/block-controls/HoverControls.hooks';
import { useEditorContext } from '@/components/editor/EditorContext';
import { isMac } from '@/utils/hotkeys';
import { IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '@/assets/add.svg';
import { ReactComponent as DragSvg } from '@/assets/drag_element.svg';
import { useSlateStatic } from 'slate-react';

export function HoverControls ({ onAdded }: {
  onAdded: (blockId: string) => void;
}) {
  const { setSelectedBlockIds } = useEditorContext();
  const [menuAnchorEl, setMenuAnchorEl] = useState<HTMLElement | null>(null);
  const openMenu = Boolean(menuAnchorEl);
  const editor = useSlateStatic() as YjsEditor;

  const { ref, cssProperty, onClickAdd, hoveredBlockId } = useHoverControls({
    disabled: openMenu,
    onAdded,
  });
  const { t } = useTranslation();

  const onClickOptions = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();

    if (!hoveredBlockId) return;
    setMenuAnchorEl(e.currentTarget as HTMLElement);
    const { selection } = editor;

    if (!selection) {
      setSelectedBlockIds?.([hoveredBlockId]);
    } else {
      const selectedPaths = getSelectedPaths(editor);

      if (!selectedPaths || selectedPaths.length === 0 || !isSameDepth(selectedPaths)) {
        setSelectedBlockIds?.([hoveredBlockId]);
      } else {
        const nodes = filterValidNodes(editor, selectedPaths);
        const blockIds = nodes.map(([node]) => node.blockId as string);

        if (blockIds.includes(hoveredBlockId)) {
          setSelectedBlockIds?.(blockIds);
        } else {
          setSelectedBlockIds?.([hoveredBlockId]);
        }
      }
    }

    const [, path] = findSlateEntryByBlockId(editor, hoveredBlockId);

    editor.select(editor.start(path));

  }, [editor, hoveredBlockId, setSelectedBlockIds]);

  return (
    <>
      <div
        ref={ref}
        data-testid={'hover-controls'}
        contentEditable={false}
        // Prevent the toolbar from being selected
        onMouseDown={(e) => {
          e.preventDefault();
        }}
        className={`absolute z-10 gap-1 flex w-[64px] flex-grow transform items-center justify-end px-1 opacity-0 ${cssProperty}`}
      >
        {/* Ensure the toolbar in middle */}
        <div className={`invisible`}>$</div>
        <Tooltip
          title={<div className={'flex flex-col'}>
            <div>{t('blockActions.addBelowTooltip')}</div>
            <div>{`${isMac() ? t('blockActions.addAboveMacCmd') : t('blockActions.addAboveCmd')} ${t('blockActions.addAboveTooltip')}`}</div>
          </div>}
          disableInteractive={true}
        >
          <IconButton
            onClick={onClickAdd}
            size={'small'}
            data-testid={'add-block'}
          >
            <AddSvg />
          </IconButton>
        </Tooltip>
        <Tooltip
          title={<div className={'flex flex-col'}>
            <div>{t('blockActions.openMenuTooltip')}</div>
          </div>}
          disableInteractive={true}
        >
          <IconButton
            data-testid={'open-block-options'}
            onClick={onClickOptions}
            size={'small'}
          >
            <DragSvg />
          </IconButton>
        </Tooltip>
      </div>
      {hoveredBlockId && openMenu && <ControlsMenu
        open={openMenu}
        anchorEl={menuAnchorEl}
        onClose={() => {
          setMenuAnchorEl(null);
          setSelectedBlockIds?.([]);
        }}
      />}
    </>
  );
}

export default HoverControls;