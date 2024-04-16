import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const ImageBlock = lazy(() => import('./ImageBlock?chunkName=media-blocks'));
