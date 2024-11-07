import { View } from '@/application/types';
import PageActions from '@/components/app/view-actions/PageActions';
import SpaceActions from '@/components/app/view-actions/SpaceActions';
import React from 'react';

export function ViewActions ({ view }: {
  view: View;
}) {
  const isSpace = view?.extra?.is_space;

  if (!view) return null;
  if (isSpace) return <SpaceActions view={view} />;
  return <PageActions view={view} />;

}

export default ViewActions;