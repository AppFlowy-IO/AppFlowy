import {
  ErrorOutline,
  HighlightOff,
  PowerSettingsNew,
  TaskAltRounded,
} from '@mui/icons-material';
import { IconButton } from '@mui/material';
import React from 'react';
import { useSnackbar, SnackbarContent, CustomContentProps } from 'notistack';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';

const CustomSnackbar = React.forwardRef<HTMLDivElement, CustomContentProps>((props, ref) => {
  const { id, message, variant } = props;
  const { closeSnackbar } = useSnackbar();

  const icons = {
    success: <TaskAltRounded className="w-6 h-6 text-green-500" />,
    error: <HighlightOff className="w-6 h-6 text-red-500" />,
    warning: <ErrorOutline className="w-6 h-6 text-yellow-500" />,
    info: <PowerSettingsNew className="w-6 h-6 text-blue-500" />,
    loading: null,
    default: null,
  };

  const colors = {
    success: 'bg-green-50 border-green-300',
    error: 'bg-red-50',
    warning: 'bg-yellow-50 border-yellow-300',
    info: 'bg-blue-50 border-blue-300',
    default: 'bg-bg-body border border-content-blue-400',
  };

  return (
    <SnackbarContent
      ref={ref}
      className={`${colors[variant]} rounded-lg shadow-lg`}
    >
      <div className="flex items-center justify-between w-full p-4">
        <div className="flex-shrink-0">
          {icons[variant]}
        </div>
        <div className="ml-3 flex-1">
          <p className="text-sm font-medium">{message}</p>
        </div>
        <IconButton
          className={'mx-2'}
          onClick={() => closeSnackbar(id)}
        >
          <CloseIcon className="h-5 w-5 text-text-caption" />
        </IconButton>
      </div>
    </SnackbarContent>
  );
});

export default CustomSnackbar;