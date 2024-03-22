import { ReactEditor } from 'slate-react';

import { withBlockDelete } from '$app/components/editor/plugins/withBlockDelete';
import { withBlockInsertBreak } from '$app/components/editor/plugins/withBlockInsertBreak';
import { withSplitNodes } from '$app/components/editor/plugins/withSplitNodes';
import { withPasted, withCopy } from '$app/components/editor/plugins/copyPasted';
import { withBlockMove } from '$app/components/editor/plugins/withBlockMove';
import { CustomEditor } from '$app/components/editor/command';

export function withBlockPlugins(editor: ReactEditor) {
  const { isElementReadOnly, isEmpty, isSelectable } = editor;

  editor.isElementReadOnly = (element) => {
    return CustomEditor.isEmbedNode(element) || isElementReadOnly(element);
  };

  editor.isEmbed = (element) => {
    return CustomEditor.isEmbedNode(element);
  };

  editor.isSelectable = (element) => {
    return !CustomEditor.isEmbedNode(element) && isSelectable(element);
  };

  editor.isEmpty = (element) => {
    return !CustomEditor.isEmbedNode(element) && isEmpty(element);
  };

  return withPasted(withBlockMove(withSplitNodes(withBlockInsertBreak(withBlockDelete(withCopy(editor))))));
}
