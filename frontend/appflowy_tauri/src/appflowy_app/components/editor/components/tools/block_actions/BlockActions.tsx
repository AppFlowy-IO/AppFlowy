import { IconButton, Tooltip } from '@mui/material';
import React, { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import BlockOperationMenu from '$app/components/editor/components/tools/block_actions/BlockOperationMenu';
import { Element } from 'slate';
import AddBlockBelow from '$app/components/editor/components/tools/block_actions/AddBlockBelow';

export function BlockActions({ node }: { node: Element | null }) {
  const { t } = useTranslation();
  const dragBtnRef = useRef<HTMLButtonElement>(null);
  const [openMenu, setOpenMenu] = useState(false);

  return (
    <>
      <AddBlockBelow node={node} />
      <Tooltip title={t('blockActions.openMenuTooltip')}>
        <IconButton
          onClick={() => {
            setOpenMenu(true);
          }}
          ref={dragBtnRef}
          size={'small'}
        >
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

export default BlockActions;
