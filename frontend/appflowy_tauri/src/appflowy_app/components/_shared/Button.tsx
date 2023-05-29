import { MouseEventHandler, MouseEvent, ReactNode, useEffect, useState } from 'react';

export const Button = ({
  size = 'primary',
  children,
  onClick,
}: {
  size?: 'primary' | 'medium' | 'small' | 'box-small-transparent' | 'medium-transparent';
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
      case 'medium-transparent':
        setCls(
          'w-[170px] h-[48px] flex items-center justify-center rounded-lg border border-main-accent text-main-accent transition-colors duration-300 hover:bg-main-hovered hover:text-white'
        );
        break;
      case 'box-small-transparent':
        setCls('text-black hover:text-main-accent w-[24px] h-[24px]');
        break;
    }
  }, [size]);

  const handleClick = (e: MouseEvent<HTMLButtonElement>) => {
    e.stopPropagation();
    onClick && onClick(e);
  };

  return (
    <button className={cls} onClick={(e) => handleClick(e)}>
      {children}
    </button>
  );
};
