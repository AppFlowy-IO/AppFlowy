import { useState } from 'react';

export const useConfirmAccount = () => {
  const [otpValues, setOtpValues] = useState('');

  const handleChange = (value: string) => {
    console.log({ value });
    setOtpValues(value);
  };

  return {
    otpValues,
    handleChange,
  };
};
