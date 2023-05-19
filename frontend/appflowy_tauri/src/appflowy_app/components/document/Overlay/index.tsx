import React from 'react';
import BlockSideToolbar from '../BlockSideToolbar';
import BlockSelection from '../BlockSelection';
import TextActionMenu from '$app/components/document/TextActionMenu';

export default function Overlay({ container }: { container: HTMLDivElement }) {
  return (
    <>
      <BlockSideToolbar container={container} />
      <TextActionMenu container={container} />
      <BlockSelection container={container} />
    </>
  );
}
