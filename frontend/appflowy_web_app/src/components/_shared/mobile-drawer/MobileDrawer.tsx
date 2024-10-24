import React, { ReactElement, useCallback } from 'react';
import SwipeableDrawer from '@mui/material/SwipeableDrawer';

import { styled } from '@mui/material/styles';

const BasePuller = styled('div')(({ theme }) => ({
  backgroundColor: theme.palette.mode === 'light' ? '#dadada' : '#666',
  borderRadius: 3,
}));

const VerticalTopPuller = styled(BasePuller)(() => ({
  width: 50,
  height: 6,
  top: 0,
}));

const VerticalBottomPuller = styled(BasePuller)(() => ({
  width: 50,
  height: 6,
  bottom: 0,
}));

const HorizontalLeftPuller = styled(BasePuller)(() => ({
  width: 6,
  height: 50,
  left: 0,
}));

const HorizontalRightPuller = styled(BasePuller)(() => ({
  width: 6,
  height: 50,
  right: 0,
}));

const PullerWrapper = styled('div')<{ anchor: 'top' | 'left' | 'bottom' | 'right' }>(
  ({ anchor }) => ({
    position: 'absolute',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 11,
    ...(anchor === 'top' && {
      bottom: 8,
      height: 6,
      left: 0,
      right: 0,
    }),
    ...(anchor === 'bottom' && {
      top: 8,
      left: 0,
      right: 0,
      height: 6,
    }),
    ...(anchor === 'left' && {
      right: 8,
      top: 0,
      bottom: 0,
      width: 6,
    }),
    ...(anchor === 'right' && {
      left: 8,
      top: 0,
      bottom: 0,
      width: 6,
    }),
  }),
);

export function MobileDrawer ({
  children,
  triggerNode,
  anchor = 'bottom',
  open,
  onOpen,
  onClose,
  swipeAreaWidth,
  swipeAreaHeight,
  maxHeight,
  showPuller = true,
}: {
  children: React.ReactNode;
  triggerNode: ReactElement;
  anchor?: 'top' | 'left' | 'bottom' | 'right';
  open: boolean;
  onOpen?: () => void;
  onClose?: () => void;
  swipeAreaWidth?: number | undefined;
  swipeAreaHeight?: number | undefined;
  maxHeight?: number | undefined;
  showPuller?: boolean;
}) {

  const toggleDrawer = useCallback((open: boolean) => {
    return (event: React.KeyboardEvent | React.MouseEvent) => {
      if (event && event.type === 'keydown' && ((event as React.KeyboardEvent).key === 'Tab' || (event as React.KeyboardEvent).key === 'Shift')) {
        return;
      }

      if (open) {
        onOpen?.();
      } else {
        onClose?.();
      }
    };
  }, [onClose, onOpen]);

  const drawerContent = (
    <>
      {showPuller && (
        <PullerWrapper anchor={anchor}>
          {anchor === 'top' && <VerticalTopPuller />}
          {anchor === 'bottom' && <VerticalBottomPuller />}
          {anchor === 'left' && <HorizontalLeftPuller />}
          {anchor === 'right' && <HorizontalRightPuller />}
        </PullerWrapper>
      )}
      {children}
    </>
  );

  return (
    <>
      {React.cloneElement(triggerNode, { ...triggerNode.props, onClick: toggleDrawer(true) })}
      <SwipeableDrawer
        anchor={anchor}
        open={open}
        onClose={toggleDrawer(false)}
        onOpen={toggleDrawer(true)}
        slotProps={{
          root: {
            className: 'text-lg',
          },
        }}
        PaperProps={{
          style: {
            width: swipeAreaWidth,
            height: swipeAreaHeight,
            maxHeight: maxHeight,
          },
        }}
      >
        {drawerContent}
      </SwipeableDrawer>
    </>
  );
}

export default MobileDrawer;