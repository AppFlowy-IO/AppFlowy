import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { nanoid } from 'nanoid';

export interface ICurrentUser {
  id: string;
  displayName: string;
  email: string;
  token: string;
}

const initialState: ICurrentUser = {
  id: nanoid(8),
  displayName: 'Me 😃',
  email: `${nanoid(4)}@gmail.com`,
  token: nanoid(8),
};

export const currentUserSlice = createSlice({
  name: 'currentUser',
  initialState: initialState,
  reducers: {
    updateUser: (state, action: PayloadAction<ICurrentUser>) => {
      return action.payload;
    },
  },
});

export const currentUserActions = currentUserSlice.actions;
