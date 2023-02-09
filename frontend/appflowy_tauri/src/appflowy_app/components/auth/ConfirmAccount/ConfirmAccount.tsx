import OtpInput from 'react18-input-otp';
import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { useConfirmAccount } from './ConfirmAccount.hooks';

export const ConfirmAccount = () => {
  const { handleChange, otpValues } = useConfirmAccount();

  return (
    <div className='flex h-screen w-full flex-col items-center justify-center gap-12 text-center'>
      <div className='flex h-10 w-10 justify-center'>
        <AppflowyLogo />
      </div>

      <div className='flex flex-col gap-2'>
        <span className='text-2xl font-semibold '>Enter the code sent to your phone</span>
        <div>
          <span className='block text-gray-500'>Confirm that this phone belongs to you.</span>
          <span className='block text-gray-500'>
            Code sent to <span className='text-black'>+86 10 6764 5489</span>
          </span>
        </div>
      </div>

      <div className='flex h-24 w-52 flex-col gap-4 '>
        <OtpInput
          value={otpValues}
          onChange={handleChange}
          numInputs={5}
          isInputNum={true}
          separator={<span> </span>}
          inputStyle='border border-gray-300 rounded-lg h-full !w-14 font-semibold   focus:ring-2 focus:ring-main-accent focus:ring-opacity-50'
          containerStyle='h-full w-full flex justify-around gap-2 '
        />

        <a href='#' className='text-xs text-main-accent hover:text-main-hovered'>
          <span> Send code again</span>
        </a>
      </div>

      <div className='w-96'>
        <button className='btn btn-primary w-full !border-0'>Get Started</button>
      </div>
    </div>
  );
};
