import { ReactEditor } from 'slate-react';

import { withBlockDeleteBackward } from '$app/components/editor/plugins/withBlockDeleteBackward';
import { withBlockInsertBreak } from '$app/components/editor/plugins/withBlockInsertBreak';
import { withMergeNodes } from '$app/components/editor/plugins/withMergeNodes';
import { withSplitNodes } from '$app/components/editor/plugins/withSplitNodes';
import { withDatabaseBlockPlugin } from '$app/components/editor/components/blocks/database';
import { withMathEquationPlugin } from '$app/components/editor/components/blocks/math_equation';
import { withPasted } from '$app/components/editor/plugins/withPasted';

export function withBlockPlugins(editor: ReactEditor) {
  return withMathEquationPlugin(
    withDatabaseBlockPlugin(
      withPasted(withSplitNodes(withMergeNodes(withBlockInsertBreak(withBlockDeleteBackward(editor)))))
    )
  );
}
