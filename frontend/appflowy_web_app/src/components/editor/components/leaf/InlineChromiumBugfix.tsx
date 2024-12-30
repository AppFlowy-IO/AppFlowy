import React from 'react';

// Put this at the start and end of an inline component to work around this Chromium bug:
// https://bugs.chromium.org/p/chromium/issues/detail?id=1249405

export const InlineChromiumBugfix = ({ className }: { className?: string }) => (
  <span
    contentEditable={false}
    className={`absolute caret-transparent ${className ?? ''}`}
    style={{
      fontSize: 0,
    }}
  >
    {String.fromCodePoint(160) /* Non-breaking space */}
  </span>
);
