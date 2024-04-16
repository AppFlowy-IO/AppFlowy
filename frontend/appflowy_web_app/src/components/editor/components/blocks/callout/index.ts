import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const Callout = lazy(() => import('./Callout?chunkName=basic-blocks'));
