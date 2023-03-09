const os = require('os')
const path = require('path')
const {expect} = require('chai')
const {spawn, spawnSync} = require('child_process')
const {Builder, By, Capabilities} = require('selenium-webdriver')
const {AuthBackendService, UserBackendService} = require("../src/appflowy_app/stores/effects/user/user_bd_svc.js");

// create the path to the expected application binary
const application = path.resolve(
    __dirname,
    '..',
    'src-tauri',
    'target',
    'release',
    'appflowy_tauri'
)

// keep track of the webdriver instance we create
let driver

// keep track of the tauri-driver process we start
let tauriDriver

before(async function () {
    // set timeout to 2 minutes to allow the program to build if it needs to
    this.timeout(120000)

    // ensure the program has been built
    spawnSync('cargo', ['build', '--release'])

    // start tauri-driver
    tauriDriver = spawn(
        path.resolve(os.homedir(), '.cargo', 'bin', 'tauri-driver'),
        [],
        {stdio: [null, process.stdout, process.stderr]}
    )

    const capabilities = new Capabilities()
    capabilities.set('tauri:options', {application})
    capabilities.setBrowserName('wry')

    // start the webdriver client
    driver = await new Builder()
        .withCapabilities(capabilities)
        .usingServer('http://localhost:4444/')
        .build()
})

after(async function () {
    // stop the webdriver session
    await driver.quit()

    // kill the tauri-driver process
    tauriDriver.kill()
})

describe('Hello Tauri', () => {
    it('should be cordial', async () => {

        await new Promise((resolve) => setTimeout(resolve, 10000));
        const text = await driver.findElement(By.css('body > h1')).getText()
        expect(text).to.match(/^[hH]ello/)
    })
})

describe('User backend service', () => {
    it('sign up', async () => {
        const service = new AuthBackendService();
        const result = await service.autoSignUp();
        expect(result.ok).toBeTruthy;
    });

    it('sign in', async () => {
        const authService = new AuthBackendService();
        const email = nanoid(4) + '@appflowy.io';
        const password = nanoid(10);
        const signUpResult = await authService.signUp({name: 'nathan', email: email, password: password});
        expect(signUpResult.ok).toBeTruthy;

        const signInResult = await authService.signIn({email: email, password: password});
        expect(signInResult.ok).toBeTruthy;
    });

    it('get user profile', async () => {
        const service = new AuthBackendService();
        const result = await service.autoSignUp();
        const userProfile = result.unwrap();

        const userService = new UserBackendService(userProfile.id);
        expect((await userService.getUserProfile()).unwrap()).toBe(userProfile);
    });
});
