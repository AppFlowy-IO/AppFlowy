import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const Mention = lazy(() => import('./Mention?chunkName=basic-blocks'));
