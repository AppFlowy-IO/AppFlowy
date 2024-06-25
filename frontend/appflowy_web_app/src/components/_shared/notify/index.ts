export const notify = {
  success: (message: string) => {
    window.toast.success(message);
  },
  error: (message: string) => {
    window.toast.error(message);
  },
  info: (message: string) => {
    window.toast.info(message);
  },
  clear: () => {
    window.toast.clear();
  },
};
