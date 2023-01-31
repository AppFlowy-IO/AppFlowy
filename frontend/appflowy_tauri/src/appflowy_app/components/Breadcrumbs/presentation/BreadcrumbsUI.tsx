import { ReactNode } from 'react';

export const BreadcrumbsUI = ({ children }: { children?: ReactNode }) => {
  return (
    <div className={'flex items-center'}>
      <div className={'ml-4 flex items-center mr-4'}>
        <button className={'px-1 py-1'}>
          <img src={'/images/home/arrow_left.svg'} />
        </button>
        <button className={'px-1 py-1'}>
          <img src={'/images/home/arrow_right.svg'} />
        </button>
      </div>
      <div className={'flex items-center'}>
        <span className={'mr-2'}>Getting Started</span>
        <span className={'mr-2'}>/</span>
        <span className={'mr-2'}>Read Me</span>
      </div>
    </div>
  );
};
