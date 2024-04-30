import { useEditorContext } from '@/components/editor/EditorContext';
import { openUrl } from '@/utils/url';
import React, { memo } from 'react';
import { Text } from 'slate';

export const Href = memo(({ children, leaf }: { leaf: Text; children: React.ReactNode }) => {
  const readonly = useEditorContext().readOnly;

  return (
    <span
      onClick={() => {
        if (readonly && leaf.href) {
          void openUrl(leaf.href, '_blank');
        }
      }}
      className={`cursor-pointer select-auto px-1 py-0.5 text-fill-default underline`}
    >
      {children}
    </span>
  );
});
