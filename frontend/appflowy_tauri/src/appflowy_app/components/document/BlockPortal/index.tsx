import ReactDOM from 'react-dom';

const BlockPortal = ({ blockId, children }: { blockId: string; children: JSX.Element }) => {
  const root = document.querySelectorAll(`[data-block-id="${blockId}"] > .block-overlay`)[0];

  return typeof document === 'object' && root ? ReactDOM.createPortal(children, root) : null;
};

export default BlockPortal;
