import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface SidebarState {
  isCollapsed: boolean;
  width: number;
  isResizing: boolean;
}

const initialState: SidebarState = {
  isCollapsed: false,
  width: 250,
  isResizing: false,
};

export const sidebarSlice = createSlice({
  name: 'sidebar',
  initialState: initialState,
  reducers: {
    toggleCollapse(state) {
      state.isCollapsed = !state.isCollapsed;
    },
    setCollapse(state, action: PayloadAction<boolean>) {
      state.isCollapsed = action.payload;
    },
    changeWidth(state, action: PayloadAction<number>) {
      state.width = action.payload;
    },
    startResizing(state) {
      state.isResizing = true;
    },
    stopResizing(state) {
      state.isResizing = false;
    },
  },
});

export const sidebarActions = sidebarSlice.actions;
