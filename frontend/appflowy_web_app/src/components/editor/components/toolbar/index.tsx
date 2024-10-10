import { ElementFallbackRender } from '@/components/error/ElementFallbackRender';
import React from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import { SelectionToolbar } from './selection-toolbar/SelectionToolbar';

function Toolbars () {
  return (
    <ErrorBoundary fallbackRender={ElementFallbackRender}>
      <SelectionToolbar />
    </ErrorBoundary>
  );
}

export default Toolbars;