import React, { useCallback } from 'react';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';
import ArrowDropDown from '@mui/icons-material/ArrowDropDown';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useTranslation } from 'react-i18next';
import Tooltip from '@mui/material/Tooltip';

function TurnIntoSelect({ id }: { id: string }) {
  const [anchorPosition, setAnchorPosition] = React.useState<{
    top: number;
    left: number;
  }>();

  const { node } = useSubscribeNode(id);
  const handleClick = useCallback((event: React.MouseEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();

    setAnchorPosition({
      top: rect.top + rect.height + 5,
      left: rect.left,
    });
  }, []);

  const handleClose = useCallback(() => {
    setAnchorPosition(undefined);
  }, []);

  const open = Boolean(anchorPosition);
  const { t } = useTranslation();

  return (
    <>
      <Tooltip disableInteractive placement={'top'} title={t('document.plugins.optionAction.turnInto')}>
        <div onClick={handleClick} className='flex cursor-pointer items-center px-2 text-sm text-fill-default'>
          <span>{node.type}</span>
          <ArrowDropDown />
        </div>
      </Tooltip>
      <TurnIntoPopover
        id={id}
        open={open}
        onClose={handleClose}
        anchorReference={'anchorPosition'}
        anchorPosition={anchorPosition}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
      />
    </>
  );
}

export default TurnIntoSelect;
