import { ReactEditor } from 'slate-react';
import { useInitialDecorateState } from '$app/components/editor/stores/decorate';
import { useInitialSelectedBlocks } from '$app/components/editor/stores/selected';
import { useInitialSlashState } from '$app/components/editor/stores/slash';
import { useInitialEditorInlineBlockState } from '$app/components/editor/stores/inline_node';
import { useEditorInitialBlockState } from '$app/components/editor/stores/block';

export * from './decorate';
export * from './selected';
export * from './slash';
export * from './inline_node';

export function useInitialEditorState(editor: ReactEditor) {
  const { decorate, decorateState } = useInitialDecorateState(editor);
  const selectedBlocks = useInitialSelectedBlocks(editor);
  const slashState = useInitialSlashState();
  const inlineBlockState = useInitialEditorInlineBlockState();
  const blockState = useEditorInitialBlockState();

  return {
    selectedBlocks,
    decorate,
    decorateState,
    slashState,
    inlineBlockState,
    blockState,
  };
}
