import { lazy } from 'react';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-expect-error
export const TodoListNode = lazy(() => import('./TodoList?chunkName=basic-blocks'));
