import { lazy } from 'react';

export * from './utils';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const Heading = lazy(() => import('./Heading?chunkName=basic-blocks'));
