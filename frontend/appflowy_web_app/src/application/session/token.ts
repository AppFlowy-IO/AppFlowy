import { emit, EventType } from '@/application/session/event';

export function refreshToken(token: string) {
  localStorage.removeItem('token');
  localStorage.setItem('token', token);
  emit(EventType.SESSION_REFRESH, token);
}

export function invalidToken() {
  localStorage.removeItem('token');
  emit(EventType.SESSION_INVALID);
}

export function isTokenValid() {
  return !!localStorage.getItem('token');
}

export function getToken() {
  return localStorage.getItem('token');
}

export function getTokenParsed(): {
  access_token: string;
  expires_at: number;
  refresh_token: string;
} | null {
  const token = getToken();

  if (!token) {
    return null;
  }

  try {
    return JSON.parse(token);
  } catch (e) {
    return null;
  }
}
