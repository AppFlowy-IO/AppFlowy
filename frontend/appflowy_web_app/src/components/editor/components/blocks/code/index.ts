import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const CodeBlock = lazy(() => import('./Code?chunkName=code-block'));
