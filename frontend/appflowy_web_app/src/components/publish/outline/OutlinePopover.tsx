import { usePublishContext } from '@/application/publish';
import AppFlowyPower from '@/components/_shared/appflowy-power/AppFlowyPower';
import Outline from '@/components/publish/outline/Outline';
import { PopperPlacementType } from '@mui/material';
import React, { ReactElement, useMemo } from 'react';
import { RichTooltip } from '@/components/_shared/popover';

export function OutlinePopover ({
  children,
  open,
  onClose,
  placement,
  onMouseEnter,
  onMouseLeave,
  drawerWidth,
}: {
  open: boolean;
  onClose: () => void;
  children: ReactElement;
  placement?: PopperPlacementType;
  onMouseEnter?: () => void;
  onMouseLeave?: () => void;
  drawerWidth: number;
}) {
  const viewMeta = usePublishContext()?.viewMeta;

  const content = useMemo(() => {
    return (
      <div
        onMouseEnter={onMouseEnter}
        onMouseLeave={onMouseLeave}

        className={'flex h-fit max-h-[590px] flex-col overflow-y-auto overflow-x-hidden appflowy-scroller'}
      >
        <Outline width={drawerWidth} />

        <AppFlowyPower divider={Boolean(viewMeta?.child_views?.length)} />
      </div>
    );
  }, [onMouseEnter, onMouseLeave, viewMeta, drawerWidth]);

  return (
    <RichTooltip PaperProps={{
      className: 'rounded-[14px] border border-tint-purple bg-bg-body m-2 overflow-hidden',
    }} open={open} onClose={onClose} content={content} placement={placement}
    >
      {children}
    </RichTooltip>
  );
}

export default OutlinePopover;
