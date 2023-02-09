import { AppflowyLogo } from '../../_shared/AppflowyLogo';
import { EyeClosed } from '../../_shared/EyeClosedSvg';
import { EyeOpened } from '../../_shared/EyeOpenSvg';

import { useSignUp } from './SignUp.hooks';

export const SignUp = () => {
  const { showPassword, onTogglePassword, showConfirmPassword, onToggleConfirmPassword } = useSignUp();

  return (
    <form method='POST' onSubmit={(e) => e.preventDefault()}>
      <div className='flex h-screen w-full flex-col items-center justify-center gap-12 text-center'>
        <div className='flex justify-center'>
          <AppflowyLogo />
        </div>

        <div>
          <span className='text-2xl font-semibold'>Sign up to Appflowy</span>
        </div>

        <div className='flex w-full max-w-[340px]  flex-col gap-6'>
          <input type='text' className='input w-full' placeholder='Phone / Email' />
          <div className='relative w-full'>
            <input type={showPassword ? 'text' : 'password'} className='input w-full !pr-10' placeholder='Password' />

            <button
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onTogglePassword}
              type='button'
            >
              {showPassword ? <EyeClosed /> : <EyeOpened />}
            </button>
          </div>

          <div className='relative w-full'>
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              className='input w-full !pr-10'
              placeholder='Repeat Password'
            />

            <button
              className='absolute right-0 top-0 flex h-full w-12 items-center justify-center '
              onClick={onToggleConfirmPassword}
              type='button'
            >
              {showConfirmPassword ? <EyeClosed /> : <EyeOpened />}
            </button>
          </div>
        </div>

        <div className='flex w-full max-w-[340px] flex-col gap-6 '>
          <button className='btn btn-primary w-full !border-0' type='submit'>
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
