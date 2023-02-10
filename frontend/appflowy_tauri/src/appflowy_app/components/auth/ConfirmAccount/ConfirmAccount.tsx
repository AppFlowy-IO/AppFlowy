import OtpInput from 'react18-input-otp';
import { AppflowyLogo } from '../../_shared/svg/AppflowyLogo';
import { useConfirmAccount } from './ConfirmAccount.hooks';
import { Button } from '../../_shared/Button';

export const ConfirmAccount = () => {
  const { handleChange, otpValues, onConfirmClick } = useConfirmAccount();

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

      <div className='flex h-24 flex-col gap-4 '>
        <div className={'flex-1'}>
          <OtpInput
            value={otpValues}
            onChange={handleChange}
            numInputs={5}
            isInputNum={true}
            separator={<span> </span>}
            inputStyle='border border-gray-300 rounded-lg h-full !w-14 font-semibold   focus:ring-2 focus:ring-main-accent focus:ring-opacity-50'
            containerStyle='h-full w-full flex justify-around gap-2 '
          />
        </div>

        <a href='#' className='text-xs text-main-accent hover:text-main-hovered'>
          <span>Send code again</span>
        </a>
      </div>

      <Button size={'primary'} onClick={() => onConfirmClick()}>
        Get Started
      </Button>
    </div>
  );
};
