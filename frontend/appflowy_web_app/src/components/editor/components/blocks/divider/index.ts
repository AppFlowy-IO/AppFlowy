import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const DividerNode = lazy(() => import('./DividerNode?chunkName=basic-blocks'));
