import { refreshToken as refreshSessionToken } from '@/application/session/token';
import axios, { AxiosInstance } from 'axios';

let axiosInstance: AxiosInstance | null = null;

export function initGrantService (baseURL: string) {
  if (axiosInstance) {
    return;
  }

  axiosInstance = axios.create({
    baseURL,
  });

  axiosInstance.interceptors.request.use((config) => {
    Object.assign(config.headers, {
      'Content-Type': 'application/json',
    });

    return config;
  });
}

export async function refreshToken (refresh_token: string) {
  const response = await axiosInstance?.post<{
    access_token: string;
    expires_at: number;
    refresh_token: string;
  }>('/token?grant_type=refresh_token', {
    refresh_token,
  });

  const newToken = response?.data;

  if (newToken) {
    refreshSessionToken(JSON.stringify(newToken));
  }

  return newToken;
}

export async function signInWithMagicLink (email: string, authUrl: string) {
  const res = await axiosInstance?.post(
    '/magiclink',
    {
      code_challenge: '',
      code_challenge_method: '',
      data: {},
      email,
    },
    {
      headers: {
        Redirect_to: authUrl,
      },
    },
  );

  return res?.data;
}

export async function settings () {
  const res = await axiosInstance?.get('/settings');

  return res?.data;
}

export function signInGoogle (authUrl: string) {
  const provider = 'google';
  const redirectTo = encodeURIComponent(authUrl);
  const accessType = 'offline';
  const prompt = 'consent';
  const baseURL = axiosInstance?.defaults.baseURL;
  const url = `${baseURL}/authorize?provider=${provider}&redirect_to=${redirectTo}&access_type=${accessType}&prompt=${prompt}`;

  window.open(url, '_current');
}

export function signInApple (authUrl: string) {
  const provider = 'apple';
  const redirectTo = encodeURIComponent(authUrl);
  const baseURL = axiosInstance?.defaults.baseURL;
  const url = `${baseURL}/authorize?provider=${provider}&redirect_to=${redirectTo}`;

  window.open(url, '_current');
}

export function signInGithub (authUrl: string) {
  const provider = 'github';
  const redirectTo = encodeURIComponent(authUrl);
  const baseURL = axiosInstance?.defaults.baseURL;
  const url = `${baseURL}/authorize?provider=${provider}&redirect_to=${redirectTo}`;

  window.open(url, '_current');
}

export function signInDiscord (authUrl: string) {
  const provider = 'discord';
  const redirectTo = encodeURIComponent(authUrl);
  const baseURL = axiosInstance?.defaults.baseURL;
  const url = `${baseURL}/authorize?provider=${provider}&redirect_to=${redirectTo}`;

  window.open(url, '_current');
}
