import React from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';

export const BreadcrumbsSkeleton = () => {
  return (
    <div className="flex items-center gap-1">
      <div className="w-5 h-5 bg-fill-list-hover rounded-full animate-pulse"></div>
      <div className="w-15 h-5 bg-fill-list-hover rounded animate-pulse"></div>
      <RightIcon className="h-5 w-5 text-gray-400" />
      <div className="w-5 h-5 bg-fill-list-hover rounded-full animate-pulse"></div>
      <div className="w-20 h-5 bg-fill-list-hover rounded animate-pulse"></div>
      <RightIcon className="h-5 w-5 text-gray-400" />
      <div className="w-5 h-5 bg-fill-list-hover rounded-full animate-pulse"></div>
      <div className="w-24 h-5 bg-fill-list-hover rounded animate-pulse"></div>
    </div>
  );
};

export default BreadcrumbsSkeleton;