import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const ToggleList = lazy(() => import('./ToggleList?chunkName=basic-blocks'));
