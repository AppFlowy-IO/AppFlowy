import OtpInput from 'react18-input-otp';
import { AppflowyLogo } from '../../_shared/AppflowyLogo';
import { useConfirmAccount } from './ConfirmAccount.hooks';

export const ConfirmAccount = () => {
  const { handleChange, otpValues } = useConfirmAccount();

  return (
    <div className=' text-center h-screen w-full flex flex-col justify-center items-center gap-6'>
      <div className='flex justify-center'>
        <AppflowyLogo />
      </div>

      <div>
        <span className='text-2xl font-semibold '>Enter the code sent to your phone</span>
      </div>

      <div>
        <span className='text-gray-500 block'>Confirm that this phone belongs to you.</span>
        <span className='text-gray-500 block'>
          Code sent to <span className='text-black'>+86 10 6764 5489</span>
        </span>
      </div>

      <div className='flex flex-col gap-4 h-24 w-52 '>
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
        <button className='w-full btn btn-primary !border-0'>Get Started</button>
      </div>
    </div>
  );
};
