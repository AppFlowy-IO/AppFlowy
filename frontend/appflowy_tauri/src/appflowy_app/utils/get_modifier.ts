export const isMac = () => {
  return navigator.userAgent.includes('Mac OS X');
};

const MODIFIERS = {
  control: 'Ctrl',
  meta: '⌘',
};

export const getModifier = () => {
  return isMac() ? MODIFIERS.meta : MODIFIERS.control;
};
