import React from 'react';

export const ToastContext = React.createContext<{
  onOpen: (message: string) => void;
  onClose: () => void;
  open: boolean;
}>({
  onOpen: () => {
    //
  },
  onClose: () => {
    //
  },
  open: false,
});

export const LISI_LIMIT = 100;