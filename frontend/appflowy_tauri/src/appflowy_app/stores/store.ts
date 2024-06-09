import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import {
  configureStore,
  createListenerMiddleware,
  TypedStartListening,
  TypedAddListener,
  ListenerEffectAPI,
  addListener,
} from '@reduxjs/toolkit';
import { pagesSlice } from './reducers/pages/slice';
import { currentUserSlice } from './reducers/current-user/slice';
import { workspaceSlice } from './reducers/workspace/slice';
import { errorSlice } from './reducers/error/slice';
import { sidebarSlice } from '$app_reducers/sidebar/slice';
import { trashSlice } from '$app_reducers/trash/slice';

const listenerMiddlewareInstance = createListenerMiddleware({
  onError: () => console.error,
});

const store = configureStore({
  reducer: {
    [pagesSlice.name]: pagesSlice.reducer,
    [currentUserSlice.name]: currentUserSlice.reducer,
    [workspaceSlice.name]: workspaceSlice.reducer,
    [errorSlice.name]: errorSlice.reducer,
    [sidebarSlice.name]: sidebarSlice.reducer,
    [trashSlice.name]: trashSlice.reducer,
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
