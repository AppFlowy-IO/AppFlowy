import {
  ErrorOutline,
  HighlightOff,
  PowerSettingsNew,
  TaskAltRounded,
} from '@mui/icons-material';
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
    default: null,
  };

  const colors = {
    success: 'bg-green-100 bg-opacity-70 border-green-300',
    error: 'bg-red-100 bg-opacity-70 border-red-300',
    warning: 'bg-yellow-100 bg-opacity-70 border-yellow-300',
    info: 'bg-blue-100 bg-opacity-70 border-blue-300',
    default: 'bg-gray-100 bg-opacity-70 border-gray-300',
  };

  return (
    <SnackbarContent ref={ref} className={`${colors[variant]} rounded-lg shadow-lg`}>
      <div className="flex items-center p-4">
        <div className="flex-shrink-0">
          {icons[variant]}
        </div>
        <div className="ml-3 flex-1">
          <p className="text-sm font-medium text-gray-900">{message}</p>
        </div>
        <button
          onClick={() => closeSnackbar(id)}
          className="ml-4 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          <span className="sr-only">Close</span>
          <CloseIcon className="h-5 w-5" />
        </button>
      </div>
    </SnackbarContent>
  );
});

export default CustomSnackbar;