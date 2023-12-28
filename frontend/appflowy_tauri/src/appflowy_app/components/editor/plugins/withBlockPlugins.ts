import { ReactEditor } from 'slate-react';

import { withBlockDeleteBackward } from '$app/components/editor/plugins/withBlockDeleteBackward';
import { withBlockInsertBreak } from '$app/components/editor/plugins/withBlockInsertBreak';
import { withSplitNodes } from '$app/components/editor/plugins/withSplitNodes';
import { withPasted } from '$app/components/editor/plugins/withPasted';
import { withBlockMove } from '$app/components/editor/plugins/withBlockMove';
import { EditorNodeType } from '$app/application/document/document.types';

const EmbedTypes: string[] = [EditorNodeType.DividerBlock, EditorNodeType.EquationBlock, EditorNodeType.GridBlock];

export function withBlockPlugins(editor: ReactEditor) {
  const { isElementReadOnly, isSelectable, isEmpty } = editor;

  editor.isElementReadOnly = (element) => {
    return EmbedTypes.includes(element.type) || isElementReadOnly(element);
  };

  editor.isSelectable = (element) => {
    return !EmbedTypes.includes(element.type) && isSelectable(element);
  };

  editor.isEmpty = (element) => {
    return !EmbedTypes.includes(element.type) && isEmpty(element);
  };

  return withPasted(withBlockMove(withSplitNodes(withBlockInsertBreak(withBlockDeleteBackward(editor)))));
}
