import { withInlines } from '@/components/editor/plugins/withInlineElement';
import { ReactEditor } from 'slate-react';

export function withPlugins(editor: ReactEditor) {
  return withInlines(editor);
}
