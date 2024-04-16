import React, { memo } from 'react';
import { Text } from 'slate';

export const Href = memo(({ children }: { leaf: Text; children: React.ReactNode }) => {
  return <span className={`cursor-pointer select-auto px-1 py-0.5 text-fill-default underline`}>{children}</span>;
});
