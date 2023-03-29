import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import {
  configureStore,
  createListenerMiddleware,
  TypedStartListening,
  TypedAddListener,
  ListenerEffectAPI,
  addListener,
} from '@reduxjs/toolkit';
import { foldersSlice } from './reducers/folders/slice';
import { pagesSlice } from './reducers/pages/slice';
import { navigationWidthSlice } from './reducers/navigation-width/slice';
import { currentUserSlice } from './reducers/current-user/slice';
import { gridSlice } from './reducers/grid/slice';
import { workspaceSlice } from './reducers/workspace/slice';
import { databaseSlice } from './reducers/database/slice';
import { documentSlice } from './reducers/document/slice';
import { boardSlice } from './reducers/board/slice';
import { errorSlice } from './reducers/error/slice';
import { activePageIdSlice } from './reducers/activePageId/slice';

const listenerMiddlewareInstance = createListenerMiddleware({
  onError: () => console.error,
});

const store = configureStore({
  reducer: {
    [foldersSlice.name]: foldersSlice.reducer,
    [pagesSlice.name]: pagesSlice.reducer,
    [activePageIdSlice.name]: activePageIdSlice.reducer,
    [navigationWidthSlice.name]: navigationWidthSlice.reducer,
    [currentUserSlice.name]: currentUserSlice.reducer,
    [gridSlice.name]: gridSlice.reducer,
    [databaseSlice.name]: databaseSlice.reducer,
    [boardSlice.name]: boardSlice.reducer,
    [documentSlice.name]: documentSlice.reducer,
    [workspaceSlice.name]: workspaceSlice.reducer,
    [errorSlice.name]: errorSlice.reducer,
  },
  middleware: (gDM) => gDM({ serializableCheck: false }).prepend(listenerMiddlewareInstance.middleware),
});

export { store };

// Infer the `RootState` and `AppDispatch` types from the store itself
export type RootState = ReturnType<typeof store.getState>;
// @see https://redux-toolkit.js.org/usage/usage-with-typescript#getting-the-dispatch-type
export type AppDispatch = typeof store.dispatch;

export type AppListenerEffectAPI = ListenerEffectAPI<RootState, AppDispatch>;

// @see https://redux-toolkit.js.org/api/createListenerMiddleware#typescript-usage
export type AppStartListening = TypedStartListening<RootState, AppDispatch>;
export type AppAddListener = TypedAddListener<RootState, AppDispatch>;

export const startAppListening = listenerMiddlewareInstance.startListening as AppStartListening;
export const addAppListener = addListener as AppAddListener;

// Use throughout your app instead of plain `useDispatch` and `useSelector`
export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
