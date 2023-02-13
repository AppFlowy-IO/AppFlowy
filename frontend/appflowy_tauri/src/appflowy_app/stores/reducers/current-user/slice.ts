import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';

export interface ICurrentUser {
  id: string;
  displayName: string;
  email: string;
  token: string;
  isAuthenticated: boolean;
}

const initialState: ICurrentUser | null = {
  id: nanoid(8),
  displayName: 'Me 😃',
  email: `${nanoid(4)}@gmail.com`,
  token: nanoid(8),
  isAuthenticated: true,
};

export const currentUserSlice = createSlice({
  name: 'currentUser',
  initialState: initialState,
  reducers: {
    updateUser: (state, action: PayloadAction<ICurrentUser>) => {
      return action.payload;
    },
    logout: (state) => {
      state.isAuthenticated = false;
    },
  },
});

export const currentUserActions = currentUserSlice.actions;
