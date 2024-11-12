import React from 'react';
import { HoverControls } from 'src/components/editor/components/toolbar/block-controls';
import { SelectionToolbar } from './selection-toolbar/SelectionToolbar';

function Toolbars ({ onAdded }: {
  onAdded: (blockId: string) => void;
}) {
  return (
    <>
      <SelectionToolbar />
      <HoverControls onAdded={onAdded} />
    </>
  );
}

export default Toolbars;