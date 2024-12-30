import React from 'react';

export const DirectoryStructure = () => {
  return (
    <div className="w-full">
      <DirectoryItem />
      <div className="pl-6">
        <DirectoryItem />
        <div className="pl-6">
          <DirectoryItem />
          <DirectoryItem />
        </div>
        <DirectoryItem />
      </div>
      <DirectoryItem />
      <div className="pl-6">
        <DirectoryItem />
        <DirectoryItem />
      </div>
    </div>
  );
};

const DirectoryItem = () => (
  <div className="flex items-center space-x-2 mb-2">
    <div className="w-5 h-5 bg-fill-list-hover rounded-full animate-pulse"></div>
    <div className="flex-1 h-5 bg-fill-list-hover rounded animate-pulse"></div>
  </div>
);

export default DirectoryStructure;