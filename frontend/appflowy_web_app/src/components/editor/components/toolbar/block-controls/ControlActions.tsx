import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { CONTAINER_BLOCK_TYPES } from '@/application/slate-yjs/command/const';
import { BlockType } from '@/application/types';
import { usePanelContext } from '@/components/editor/components/panels/Panels.hooks';
import { PanelType } from '@/components/editor/components/panels/PanelsContext';
import ControlsMenu from '@/components/editor/components/toolbar/block-controls/ControlsMenu';
import { getRangeRect } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { useEditorContext } from '@/components/editor/EditorContext';
import { isMac } from '@/utils/hotkeys';
import { IconButton, Tooltip } from '@mui/material';
import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '@/assets/add.svg';
import { ReactComponent as DragSvg } from '@/assets/drag_element.svg';
import { Transforms } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { filterValidNodes, findSlateEntryByBlockId, getSelectedPaths } from '@/application/slate-yjs/utils/editor';

function ControlActions({ setOpenMenu, blockId }: {
  blockId: string | null;
  setOpenMenu?: (open: boolean) => void;
}) {
  const { setSelectedBlockIds } = useEditorContext();
  const [menuAnchorEl, setMenuAnchorEl] = useState<HTMLElement | null>(null);
  const openMenu = Boolean(menuAnchorEl);

  const editor = useSlateStatic() as YjsEditor;
  const { t } = useTranslation();

  const {
    openPanel,
  } = usePanelContext();

  const onAdded = useCallback(() => {

    setTimeout(() => {
      const rect = getRangeRect();

      if (!rect) return;

      openPanel(PanelType.Slash, { top: rect.top, left: rect.left });
    }, 50);

  }, [openPanel]);

  const onClickOptions = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();

    if (!blockId) return;
    setOpenMenu?.(true);
    setMenuAnchorEl(e.currentTarget as HTMLElement);
    const { selection } = editor;
    const [, nodePath] = findSlateEntryByBlockId(editor, blockId);

    if (!selection) {
      setSelectedBlockIds?.([blockId]);
    } else {
      const selectedPaths = getSelectedPaths(editor);

      if (!selectedPaths || selectedPaths.length === 0) {
        setSelectedBlockIds?.([blockId]);
      } else {
        const nodes = filterValidNodes(editor, selectedPaths);
        const blockIds = nodes.map(([node]) => node.blockId as string);

        if (blockIds.includes(blockId)) {
          setSelectedBlockIds?.(blockIds);
        } else {
          setSelectedBlockIds?.([blockId]);
        }
      }
    }

    editor.select(editor.start(nodePath));

  }, [setOpenMenu, editor, blockId, setSelectedBlockIds]);

  const onClickAdd = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    if (!blockId) return;
    const [node, path] = findSlateEntryByBlockId(editor, blockId);
    const start = editor.start(path);

    ReactEditor.focus(editor);
    Transforms.select(editor, start);

    const type = node.type as BlockType;

    if (CustomEditor.getBlockTextContent(node, 2) === '' && [...CONTAINER_BLOCK_TYPES, BlockType.HeadingBlock].includes(type)) {
      onAdded();
      return;
    }

    if (e.altKey) {
      CustomEditor.addAboveBlock(editor, blockId, BlockType.Paragraph, {});
    } else {
      CustomEditor.addBelowBlock(editor, blockId, BlockType.Paragraph, {});
    }

    onAdded();
  }, [editor, blockId, onAdded]);

  return (
    <div className={'gap-1 flex w-full flex-grow transform items-center justify-end'}>
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
          <AddSvg/>
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
          <DragSvg/>
        </IconButton>
      </Tooltip>
      {blockId && openMenu && <ControlsMenu
        open={openMenu}
        anchorEl={menuAnchorEl}
        onClose={() => {
          setSelectedBlockIds?.([]);
          setMenuAnchorEl(null);
          setOpenMenu?.(false);
        }}
      />}
    </div>
  );
}

export default ControlActions;