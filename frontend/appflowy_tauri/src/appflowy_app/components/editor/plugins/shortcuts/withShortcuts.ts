import { ReactEditor } from 'slate-react';
import { withMarkdownShortcuts } from '$app/components/editor/plugins/shortcuts/withMarkdownShortcuts';

export function withShortcuts(editor: ReactEditor) {
  return withMarkdownShortcuts(editor);
}
