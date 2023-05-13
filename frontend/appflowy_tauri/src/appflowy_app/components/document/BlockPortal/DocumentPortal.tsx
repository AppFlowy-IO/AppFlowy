import ReactDOM from 'react-dom';

const DocumentPortal = ({ children }: { children: JSX.Element }) => {
  const root = document.querySelector('.appflowy-doc-overlay');

  return typeof document === 'object' && root ? ReactDOM.createPortal(children, root) : null;
};

export default DocumentPortal;
