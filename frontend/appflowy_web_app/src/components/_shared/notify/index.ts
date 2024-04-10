import toast from 'react-hot-toast';

const commonOptions = {
  style: {
    background: 'var(--bg-base)',
    color: 'var(--text-title)',
    shadows: 'var(--shadow)',
  },
};

export const notify = {
  success: (message: string) => {
    toast.success(message, commonOptions);
  },
  error: (message: string) => {
    toast.error(message, commonOptions);
  },
  loading: (message: string) => {
    toast.loading(message, commonOptions);
  },
  info: (message: string) => {
    toast(message, commonOptions);
  },
  clear: () => {
    toast.dismiss();
  },
};
