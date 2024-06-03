import { FC, useMemo } from 'react';

export interface TagProps {
  color?: string;
  label?: string;
  size?: 'small' | 'medium';
}

export const Tag: FC<TagProps> = ({ color, size = 'small', label }) => {
  const className = useMemo(() => {
    const classList = ['rounded-md', 'font-medium', 'leading-[18px]'];

    if (color) classList.push(`text-text-title`);
    if (size === 'small') classList.push('px-2', 'py-[2px]');
    if (size === 'medium') classList.push('px-3', 'py-1');
    return classList.join(' ');
  }, [color, size]);

  return (
    <div
      style={{
        backgroundColor: color ? `var(${color})` : undefined,
      }}
      className={className}
    >
      {label}
    </div>
  );
};
