import React from 'react';
import { HoverControls } from 'src/components/editor/components/toolbar/block-controls';
import { SelectionToolbar } from './selection-toolbar/SelectionToolbar';

function Toolbars () {
  return (
    <>
      <SelectionToolbar />
      <HoverControls />
    </>
  );
}

export default Toolbars;