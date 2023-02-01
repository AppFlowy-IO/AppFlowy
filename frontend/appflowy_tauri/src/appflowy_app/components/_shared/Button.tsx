import { MouseEventHandler, ReactNode, useEffect, useState } from 'react';

export const Button = ({
  size = 'primary',
  children,
  onClick,
}: {
  size?: 'primary' | 'medium' | 'small';
  children: ReactNode;
  onClick?: MouseEventHandler<HTMLButtonElement>;
}) => {
  const [cls, setCls] = useState('');
  useEffect(() => {
    switch (size) {
      case 'primary':
        setCls('w-[340px] h-[48px] flex items-center justify-center rounded-lg bg-main-accent text-white');
        break;
      case 'medium':
        setCls('w-[170px] h-[48px] flex items-center justify-center rounded-lg bg-main-accent text-white');
        break;
      case 'small':
        setCls('w-[68px] h-[32px] flex items-center justify-center rounded-lg bg-main-accent text-white text-xs');
        break;
    }
  }, [size]);

  return (
    <button className={cls} onClick={onClick}>
      {children}
    </button>
  );
};
