import { AppflowyLogo } from '../../_shared/AppflowyLogo';
import { EyeClosed } from '../../_shared/EyeClosedSvg';
import { EyeOpened } from '../../_shared/EyeOpenSvg';

import { useSignUp } from './SignUp.hooks';

export const SignUp = () => {
  const { showPassword, onTogglePassword, showConfirmPassword, onToggleConfirmPassword } = useSignUp();

  return (
    <form method='POST' onSubmit={(e) => e.preventDefault()}>
      <div className='text-center h-screen w-full flex flex-col justify-center items-center gap-12'>
        <div className='flex justify-center'>
          <AppflowyLogo />
        </div>

        <div>
          <span className='text-2xl font-semibold'>Sign up to Appflowy</span>
        </div>

        <div className='flex flex-col gap-6  max-w-[340px] w-full'>
          <input type='text' className='input w-full' placeholder='Phone / Email' />
          <div className='w-full relative'>
            <input type={showPassword ? 'text' : 'password'} className='input !pr-10 w-full' placeholder='Password' />

            <button
              className='absolute right-0 top-0 h-full w-12 flex justify-center items-center '
              onClick={onTogglePassword}
              type='button'
            >
              {showPassword ? <EyeClosed /> : <EyeOpened />}
            </button>
          </div>

          <div className='w-full relative'>
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              className='input !pr-10 w-full'
              placeholder='Repeat Password'
            />

            <button
              className='absolute right-0 top-0 h-full w-12 flex justify-center items-center '
              onClick={onToggleConfirmPassword}
              type='button'
            >
              {showConfirmPassword ? <EyeClosed /> : <EyeOpened />}
            </button>
          </div>
        </div>

        <div className='flex flex-col gap-6 max-w-[340px] w-full '>
          <button className='w-full btn btn-primary !border-0' type='submit'>
            Get Started
          </button>

          {/* signup link */}
          <div className='flex justify-center'>
            <span className='text-xs text-gray-500'>
              Already have an account?
              <a href='/auth/login' className=' text-main-accent hover:text-main-hovered'>
                <span> Sign in</span>
              </a>
            </span>
          </div>
        </div>
      </div>
    </form>
  );
};
