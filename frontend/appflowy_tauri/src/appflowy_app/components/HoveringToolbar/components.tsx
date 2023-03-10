import ReactDOM from 'react-dom';
export const Portal = ({ blockId, children }: { blockId: string; children: JSX.Element }) => {
  const root = document.querySelectorAll(`[data-block-id=${blockId}]`)[0];
  return typeof document === 'object' && root ? ReactDOM.createPortal(children, root) : null;
};
