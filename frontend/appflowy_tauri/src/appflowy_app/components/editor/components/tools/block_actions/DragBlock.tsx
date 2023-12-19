import React, { useCallback, useRef, useState } from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import BlockOperationMenu from '$app/components/editor/components/tools/block_actions/BlockOperationMenu';
import { Element } from 'slate';

function DragBlock({ node, onSelectedBlock }: { node: Element; onSelectedBlock: (blockId: string) => void }) {
  const dragBtnRef = useRef<HTMLButtonElement>(null);
  const [openMenu, setOpenMenu] = useState(false);
  const { t } = useTranslation();

  const handleClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      setOpenMenu(true);
      if (!node || !node.blockId) return;

      onSelectedBlock(node.blockId);
    },
    [node, onSelectedBlock]
  );

  return (
    <>
      <Tooltip title={t('blockActions.openMenuTooltip')}>
        <IconButton onClick={handleClick} ref={dragBtnRef} size={'small'}>
          <DragSvg />
        </IconButton>
      </Tooltip>
      {openMenu && node && (
        <BlockOperationMenu
          onMouseMove={(e) => {
            e.stopPropagation();
          }}
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'right',
          }}
          transformOrigin={{
            vertical: 'center',
            horizontal: 'left',
          }}
          node={node}
          open={openMenu}
          anchorEl={dragBtnRef.current}
          onClose={() => setOpenMenu(false)}
        />
      )}
    </>
  );
}

export default DragBlock;
