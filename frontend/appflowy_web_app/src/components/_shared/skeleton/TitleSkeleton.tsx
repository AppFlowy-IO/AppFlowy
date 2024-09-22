import React from 'react';

function TitleSkeleton () {
  return (
    <div className="w-full flex gap-2 items-center h-20 mb-2">
      <div className="flex-shrink-0 w-16 h-16 bg-fill-list-hover rounded-full animate-pulse"></div>
      <div className="ml-4 flex-grow">
        <div className="h-10 bg-fill-list-hover rounded animate-pulse"></div>
      </div>
    </div>
  );
}

export default TitleSkeleton;