import React from 'react';
import BlockSideToolbar from '../BlockSideToolbar';
import BlockSelection from '../BlockSelection';
import TextActionMenu from '$app/components/document/TextActionMenu';
import BlockSlash from '$app/components/document/BlockSlash';
import { useCopy } from '$app/components/document/_shared/CopyPasteHooks/useCopy';
import { usePaste } from '$app/components/document/_shared/CopyPasteHooks/usePaste';
import EditPopover from '$app/components/document/_shared/TextLink/EditPopover';

export default function Overlay({ container }: { container: HTMLDivElement }) {
  useCopy(container);
  usePaste(container);
  return (
    <>
      <BlockSideToolbar container={container} />
      <TextActionMenu container={container} />
      <BlockSelection container={container} />
      <BlockSlash />
      <EditPopover />
    </>
  );
}
