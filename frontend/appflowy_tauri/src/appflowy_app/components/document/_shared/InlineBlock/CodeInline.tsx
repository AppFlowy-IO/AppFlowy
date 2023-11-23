import React from 'react';

function CodeInline({ children, selected }: { text: string; children: React.ReactNode; selected: boolean }) {
  return (
    <span
      className={'bg-content-blue-50 py-1'}
      style={{
        fontSize: '85%',
        lineHeight: 'normal',
        backgroundColor: selected ? 'var(--content-blue-100)' : undefined,
      }}
    >
      {children}
    </span>
  );
}

export default CodeInline;
