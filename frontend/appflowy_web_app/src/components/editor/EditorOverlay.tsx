import React from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import Toolbars from './components/toolbar';
import Panels from './components/panels';
import BlockPopover from './components/block-popover';

function EditorOverlay () {

  return (
    <ErrorBoundary fallbackRender={() => null}>
      <Toolbars />
      <Panels />
      <BlockPopover />

    </ErrorBoundary>
  );
}

export default EditorOverlay;