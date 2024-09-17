import React from 'react';
import TitleSkeleton from '@/components/_shared/skeleton/TitleSkeleton';

function DocumentSkeleton () {
  return (
    <div className="flex flex-col items-center w-full max-w-full mx-auto">
      <div
        className="w-full h-[40vh] max-h-[288px] min-h-[130px] max-sm:h-[180px] bg-fill-list-hover animate-pulse"
      ></div>

      <div className="h-[60px]"></div>

      <div className="w-full max-w-[964px] px-6 flex items-center h-20 mb-2">
        <TitleSkeleton />
      </div>

      <div className="w-full max-w-[964px] px-6 mt-2">
        <div className="h-10 bg-fill-list-hover w-full mb-4 animate-pulse"></div>
        <div className="h-6 bg-fill-list-hover w-1/2 mb-4 animate-pulse"></div>
        <div className="h-8 bg-fill-list-hover w-3/5 mb-4 animate-pulse"></div>
        <div className="h-7 bg-fill-list-hover w-4/5 mb-4 animate-pulse"></div>
        <div className="h-5 bg-fill-list-hover w-full mb-2 animate-pulse"></div>
        <div className="h-5 bg-fill-list-hover w-full animate-pulse"></div>
      </div>
    </div>
  );
}

export default DocumentSkeleton;