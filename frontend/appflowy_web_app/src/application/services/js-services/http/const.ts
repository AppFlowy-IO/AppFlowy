export enum URL_NAME {
  SIGN_IN_WITH_EMAIL,
  GET_USER,
  LOGOUT,
  REFRESH_TOKEN,
  GET_WORKSPACES,
  GET_OBJECT,
}

export const gotrueHttpUrls = {
  [URL_NAME.SIGN_IN_WITH_EMAIL]: '/token?grant_type=password',
  [URL_NAME.GET_USER]: '/user',
  [URL_NAME.LOGOUT]: '/logout',
  [URL_NAME.REFRESH_TOKEN]: '/token?grant_type=refresh_token',
};

export const baseHttpUrls = {
  [URL_NAME.GET_WORKSPACES]: '/api/workspace',
  [URL_NAME.GET_OBJECT]: (workspaceId: string, objectId: string) => `/api/workspace/${workspaceId}/collab/${objectId}`,
};

export const ACCESS_TOKEN_NAME = 'access_token';
export const REFRESH_TOKEN_NAME = 'refresh_token';
export const TOKEN_TYPE_NAME = 'token_type';

export const AUTHORIZATION_NAME = 'Authorization';
