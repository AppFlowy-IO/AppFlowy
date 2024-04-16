import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const Quote = lazy(() => import('./Quote?chunkName=basic-blocks'));
