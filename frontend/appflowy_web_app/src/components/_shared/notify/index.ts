import { InfoProps } from '@/components/_shared/notify/InfoSnackbar';

export const notify = {
  success: (message: string) => {
    window.toast.success(message);
  },
  error: (message: string) => {
    window.toast.error(message);
  },
  default: (message: string) => {
    window.toast.default(message);
  },
  warning: (message: string) => {
    window.toast.warning(message);
  },
  info: (props: InfoProps) => {
    window.toast.info({
      ...props,
      variant: 'info',
      anchorOrigin: {
        vertical: 'bottom',
        horizontal: 'center',
      },
    });
  },
  clear: () => {
    window.toast.clear();
  },
};

export * from './InfoSnackbar';
