import React from 'react';
import BlockSideToolbar from '../BlockSideToolbar';
import BlockSelection from '../BlockSelection';
import TextActionMenu from '$app/components/document/TextActionMenu';
import BlockSlash from '$app/components/document/BlockSlash';
import { useCopy } from '$app/components/document/_shared/CopyPasteHooks/useCopy';
import { usePaste } from '$app/components/document/_shared/CopyPasteHooks/usePaste';
import LinkEditPopover from '$app/components/document/_shared/TextLink/LinkEditPopover';
import { useUndoRedo } from '$app/components/document/_shared/UndoHooks/useUndoRedo';
import TemporaryPopover from '$app/components/document/_shared/TemporaryInput/TemporaryPopover';

export default function Overlay({ container }: { container: HTMLDivElement }) {
  useCopy(container);
  usePaste(container);
  useUndoRedo(container);
  return (
    <>
      <BlockSideToolbar container={container} />
      <TextActionMenu container={container} />
      <BlockSelection container={container} />
      <BlockSlash container={container} />
      <LinkEditPopover />
      <TemporaryPopover />
    </>
  );
}
