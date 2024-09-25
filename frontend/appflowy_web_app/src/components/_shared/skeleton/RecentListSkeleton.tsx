import React from 'react';

const RecentListSkeleton = ({ rows = 5 }) => {
  return (
    <div className="w-full max-w-[360px] bg-bg-body">
      {[...Array(rows)].map((_, index) => (
        <div key={index} className="flex items-center my-1 mx-2 gap-2">
          <div className="w-5 h-5 bg-fill-list-hover rounded-full animate-pulse"></div>
          <div className="flex-1 h-5 bg-fill-list-hover rounded animate-pulse"></div>
        </div>
      ))}
    </div>
  );
};

export default RecentListSkeleton;