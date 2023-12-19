import { ReactEditor } from 'slate-react';
import { withMarkdownShortcuts } from '$app/components/editor/components/editor/shortcuts/withMarkdownShortcuts';
import { withCommandShortcuts } from '$app/components/editor/components/editor/shortcuts/withCommandShortcuts';

export function withShortcuts(editor: ReactEditor) {
  return withMarkdownShortcuts(withCommandShortcuts(editor));
}
