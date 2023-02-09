import { useState } from 'react';

export const useSignUp = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  function onTogglePassword() {
    setShowPassword(!showPassword);
  }

  function onToggleConfirmPassword() {
    setShowConfirmPassword(!showConfirmPassword);
  }

  return { showPassword, onTogglePassword, showConfirmPassword, onToggleConfirmPassword };
};
