import React, { useCallback, useContext, useRef, useState } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import BlockOperationMenu from '$app/components/editor/components/tools/block_actions/BlockOperationMenu';
import { Element } from 'slate';
import { EditorSelectedBlockContext } from '$app/components/editor/components/editor/Editor.hooks';

function BlockMenu({ node }: { node?: Element }) {
  const dragBtnRef = useRef<HTMLButtonElement>(null);
  const [openMenu, setOpenMenu] = useState(false);
  const { t } = useTranslation();
  const [selectedNode, setSelectedNode] = useState<Element>();
  const selectedBlockContext = useContext(EditorSelectedBlockContext);

  const handleClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      setOpenMenu(true);
      if (!node || !node.blockId) return;
      setSelectedNode(node);
      selectedBlockContext.clear();
      selectedBlockContext.add(node.blockId);
    },
    [node, selectedBlockContext]
  );

  return (
    <>
      <Tooltip title={t('blockActions.openMenuTooltip')}>
        <IconButton onClick={handleClick} ref={dragBtnRef} size={'small'}>
          <DragSvg />
        </IconButton>
      </Tooltip>
      {openMenu && selectedNode && (
        <BlockOperationMenu
          onMouseMove={(e) => {
            e.stopPropagation();
          }}
          anchorOrigin={{
            vertical: 'center',
            horizontal: 'left',
          }}
          transformOrigin={{
            vertical: 'center',
            horizontal: 'right',
          }}
          PaperProps={{
            onClick: (e) => {
              e.stopPropagation();
            },
          }}
          node={selectedNode}
          open={openMenu}
          anchorEl={dragBtnRef.current}
          onClose={() => {
            setOpenMenu(false);
          }}
        />
      )}
    </>
  );
}

export default BlockMenu;
