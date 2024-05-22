import { Box, ClickAwayListener, Fade, Paper, Popper, PopperPlacementType } from '@mui/material';
import React, { ReactElement, useEffect } from 'react';

interface Props {
  content: ReactElement;
  children: ReactElement;
  open: boolean;
  onClose: () => void;
  placement?: PopperPlacementType;
}

export const RichTooltip = ({ placement = 'top', open, onClose, content, children }: Props) => {
  const [childNode, setChildNode] = React.useState<HTMLElement | null>(null);
  const [, setTransitioning] = React.useState(false);

  useEffect(() => {
    if (open) {
      setTransitioning(true);
    }
  }, [open]);
  return (
    <>
      {React.cloneElement(children, { ...children.props, ref: setChildNode })}
      <Popper
        open={open}
        anchorEl={childNode}
        placement={placement}
        transition
        style={{ zIndex: 2000 }}
        modifiers={[
          {
            name: 'flip',
            enabled: true,
          },
          {
            name: 'preventOverflow',
            enabled: true,
          },
        ]}
      >
        {({ TransitionProps }) => (
          <Fade
            {...TransitionProps}
            timeout={350}
            onTransitionEnd={() => {
              setTransitioning(false);
            }}
          >
            <Paper className={'bg-transparent shadow-none'}>
              <ClickAwayListener onClickAway={onClose}>
                <Paper className={'m-2 rounded-md border border-line-divider bg-bg-body'}>
                  <Box>{content}</Box>
                </Paper>
              </ClickAwayListener>
            </Paper>
          </Fade>
        )}
      </Popper>
    </>
  );
};

export default RichTooltip;
