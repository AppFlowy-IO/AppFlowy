import { withDelete } from '@/components/editor/plugins/withDelete';
import { withInsertBreak } from '@/components/editor/plugins/withInsertBreak';
import { withInsertText } from '@/components/editor/plugins/withInsertText';
import { withMarkdown } from '@/components/editor/plugins/withMarkdown';
import { ReactEditor } from 'slate-react';

export function withPlugins (editor: ReactEditor) {
  return withMarkdown(withInsertBreak(withDelete(withInsertText(editor))));
}
