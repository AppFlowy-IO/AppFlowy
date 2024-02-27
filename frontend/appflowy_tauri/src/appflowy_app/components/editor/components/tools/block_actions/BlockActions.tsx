import React from 'react';

import { Element } from 'slate';
import AddBlockBelow from '$app/components/editor/components/tools/block_actions/AddBlockBelow';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import { IconButton, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';

export function BlockActions({
  node,
  onClickDrag,
}: {
  node?: Element;
  onClickDrag: (e: React.MouseEvent<HTMLButtonElement>) => void;
}) {
  const { t } = useTranslation();

  return (
    <>
      <AddBlockBelow node={node} />
      <Tooltip disableInteractive={true} title={t('blockActions.openMenuTooltip')}>
        <IconButton onClick={onClickDrag} size={'small'}>
          <DragSvg />
        </IconButton>
      </Tooltip>
    </>
  );
}

export default BlockActions;
