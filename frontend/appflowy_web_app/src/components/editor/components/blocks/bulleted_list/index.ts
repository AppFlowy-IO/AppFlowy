import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const BulletedList = lazy(() => import('./BulletedList?chunkName=basic-blocks'));

export * from './BulletedListIcon';
