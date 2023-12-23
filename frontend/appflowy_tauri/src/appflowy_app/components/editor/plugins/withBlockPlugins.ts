import { ReactEditor } from 'slate-react';

import { withBlockDeleteBackward } from '$app/components/editor/plugins/withBlockDeleteBackward';
import { withBlockInsertBreak } from '$app/components/editor/plugins/withBlockInsertBreak';
import { withSplitNodes } from '$app/components/editor/plugins/withSplitNodes';
import { withDatabaseBlockPlugin } from '$app/components/editor/components/blocks/database';
import { withMathEquationPlugin } from '$app/components/editor/components/blocks/math_equation';
import { withPasted } from '$app/components/editor/plugins/withPasted';
import { withBlockMove } from '$app/components/editor/plugins/withBlockMove';

export function withBlockPlugins(editor: ReactEditor) {
  return withMathEquationPlugin(
    withPasted(
      withDatabaseBlockPlugin(withBlockMove(withSplitNodes(withBlockInsertBreak(withBlockDeleteBackward(editor)))))
    )
  );
}
