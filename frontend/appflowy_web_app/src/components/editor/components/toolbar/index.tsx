import { ElementFallbackRender } from '@/components/error/ElementFallbackRender';
import React from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import { HoverControls } from 'src/components/editor/components/toolbar/block-controls';
import { SelectionToolbar } from './selection-toolbar/SelectionToolbar';

function Toolbars () {
  return (
    <ErrorBoundary fallbackRender={ElementFallbackRender}>
      <SelectionToolbar />
      <HoverControls />
    </ErrorBoundary>
  );
}

export default Toolbars;