const tokenKey = 'token';

export function readTokenStr () {
  return sessionStorage.getItem(tokenKey);
}

export function getAuthInfo () {
  const token = readTokenStr() || '';

  try {
    const info = JSON.parse(token);
    return {
      uuid: info.user.id,
      access_token: info.access_token,
      email: info.user.email,
    };
  } catch (e) {
    return;
  }
}

export function writeToken (token: string) {
  if (!token) {
    invalidToken();
    return;
  }
  sessionStorage.setItem(tokenKey, token);
}

export function invalidToken () {
  sessionStorage.removeItem(tokenKey);
  window.location.reload();
}

