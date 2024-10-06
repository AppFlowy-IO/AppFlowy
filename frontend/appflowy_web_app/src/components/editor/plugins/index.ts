import { withDelete } from '@/components/editor/plugins/withDelete';
import { withInsertBreak } from '@/components/editor/plugins/withInsertBreak';
import { ReactEditor } from 'slate-react';

export function withPlugins (editor: ReactEditor) {
  return withInsertBreak(withDelete(editor));
}
