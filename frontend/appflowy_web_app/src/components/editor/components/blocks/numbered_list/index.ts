import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const NumberedList = lazy(() => import('./NumberedList?chunkName=basic-blocks'));

export * from './NumberListIcon';
