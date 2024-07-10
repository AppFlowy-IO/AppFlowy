import React from 'react';

function QuoteIcon({ className }: { className: string }) {
  return (
    <span data-playwright-selected={false} contentEditable={false} draggable={false} className={`${className}`}>
      <div className={'h-full w-[4px] bg-fill-default'}></div>
    </span>
  );
}

export default QuoteIcon;
