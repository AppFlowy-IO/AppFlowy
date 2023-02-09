import { useState } from 'react';

export const useLogin = () => {
  const [showPassword, setShowPassword] = useState(false);

  function onTogglePassword() {
    setShowPassword(!showPassword);
  }

  return { showPassword, onTogglePassword };
};
