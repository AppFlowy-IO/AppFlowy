import React, { useCallback, useMemo, useState } from 'react';
import { Alert, Portal, Snackbar } from '@mui/material';
import Slide, { SlideProps } from '@mui/material/Slide';

function SlideTransition(props: SlideProps) {
  return <Slide {...props} direction='up' />;
}

interface MessageProps {
  message?: string;
  key?: string;
  duration?: number;
  type?: 'success' | 'error';
}
export function useMessage() {
  const [state, setState] = useState<MessageProps>();
  const show = useCallback((message: MessageProps) => {
    setState(message);
  }, []);
  const hide = useCallback(() => {
    setState(undefined);
  }, []);

  const contentHolder = useMemo(() => {
    const open = !!state;

    return (
      <Portal>
        <Snackbar
          autoHideDuration={state?.duration}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
          open={open}
          onClose={hide}
          TransitionProps={{ onExited: hide }}
          message={state?.message}
          key={state?.key}
          TransitionComponent={SlideTransition}
          children={
            <>
              {state?.type ? (
                <Alert severity={state.type} sx={{ width: '100%' }}>
                  {state.message}
                </Alert>
              ) : null}
            </>
          }
        />
      </Portal>
    );
  }, [hide, state]);

  return {
    show,
    hide,
    contentHolder,
  };
}
