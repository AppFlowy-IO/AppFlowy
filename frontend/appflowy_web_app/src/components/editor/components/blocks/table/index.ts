import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const TableBlock = lazy(() => import('./Table?chunkName=media-blocks'));

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const TableCellBlock = lazy(() => import('./TableCell?chunkName=media-blocks'));
