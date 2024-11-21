import { usePanelContext } from '@/components/editor/components/panels/Panels.hooks';
import { PanelType } from '@/components/editor/components/panels/PanelsContext';
import { getRangeRect } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { ElementFallbackRender } from '@/components/error/ElementFallbackRender';
import React, { useCallback } from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import Toolbars from './components/toolbar';
import Panels from './components/panels';
import BlockPopover from './components/block-popover';

function EditorOverlay () {
  const {
    openPanel,
  } = usePanelContext();

  const handleBlockAdded = useCallback(() => {

    setTimeout(() => {
      const rect = getRangeRect();

      if (!rect) return;

      openPanel(PanelType.Slash, { top: rect.top, left: rect.left });
    }, 50);

  }, [openPanel]);

  return (
    <ErrorBoundary fallbackRender={ElementFallbackRender}>
      <Toolbars onAdded={handleBlockAdded} />
      <Panels />
      <BlockPopover />

    </ErrorBoundary>
  );
}

export default EditorOverlay;