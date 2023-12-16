import React from 'react';

function Placeholder({
  children,
  attributes,
}: {
  children: React.ReactNode;
  attributes: React.HTMLAttributes<HTMLDivElement>;
}) {
  // const selected = useSelected();

  const selected = false;

  return (
    <div {...attributes} className={`${selected ? 'hidden' : ''} h-full whitespace-nowrap`}>
      <div className={'flex h-full items-center'}>{children}</div>
    </div>
  );
}

export default Placeholder;
