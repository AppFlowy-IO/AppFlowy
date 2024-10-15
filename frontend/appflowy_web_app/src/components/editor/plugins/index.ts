import { withDelete } from '@/components/editor/plugins/withDelete';
import { withInsertBreak } from '@/components/editor/plugins/withInsertBreak';
import { withInsertText } from '@/components/editor/plugins/withInsertText';
import { withMarkdown } from '@/components/editor/plugins/withMarkdown';
import { withPasted } from '@/components/editor/plugins/withPasted';
import { ReactEditor } from 'slate-react';

export function withPlugins (editor: ReactEditor) {
  return withPasted(withMarkdown(withInsertBreak(withDelete(withInsertText(editor)))));
}
