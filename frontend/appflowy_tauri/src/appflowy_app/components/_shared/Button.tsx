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
        setCls('w-[340px] h-[48px] flex items-center justify-center rounded-lg bg-content-default text-content-onfill');
        break;
      case 'medium':
        setCls('w-[170px] h-[48px] flex items-center justify-center rounded-lg bg-content-default text-content-onfill');
        break;
      case 'small':
        setCls(
          'w-[68px] h-[32px] flex items-center justify-center rounded-lg bg-content-default text-content-onfill text-xs hover:bg-content-hover'
        );
        break;
      case 'medium-transparent':
        setCls(
          'w-[170px] h-[48px] flex items-center justify-center rounded-lg border border-content-default text-content-default transition-colors duration-300 hover:bg-content-hover hover:text-content-onfill'
        );
        break;
      case 'box-small-transparent':
        setCls('text-icon-default w-[24px] h-[24px] rounded hover:bg-fill-hover');
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
