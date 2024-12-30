import React from 'react';

function TabbarSkeleton () {
  const tabCount = 4;

  return (
    <div className="w-full mx-auto">
      <div className="border-b border-line-divider">
        <nav className="-mb-px flex">
          {[...Array(tabCount)].map((_, index) => (
            <div key={index} className="mr-2">
              <div className="border-b-2 border-transparent px-4 py-2 min-w-[100px]">
                <div className="h-5 bg-fill-list-hover rounded w-20 animate-pulse"></div>
              </div>
            </div>
          ))}
        </nav>
      </div>
    </div>
  );
}

export default TabbarSkeleton;