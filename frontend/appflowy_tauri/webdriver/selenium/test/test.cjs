const os = require("os");
const path = require("path");
const { expect } = require("chai");
const { spawn, spawnSync } = require("child_process");
const { Builder, By, Capabilities, until } = require("selenium-webdriver");
const { elementIsVisible, elementLocated } = require("selenium-webdriver/lib/until.js");

// create the path to the expected application binary
const application = path.resolve(
  __dirname,
  "..",
  "..",
  "..",
  "src-tauri",
  "target",
  "release",
  "appflowy_tauri"
);

// keep track of the webdriver instance we create
let driver;

// keep track of the tauri-driver process we start
let tauriDriver;

before(async function() {
  // set timeout to 2 minutes to allow the program to build if it needs to
  this.timeout(120000);

  // ensure the program has been built
  spawnSync("cargo", ["build", "--release"]);

  // start tauri-driver
  tauriDriver = spawn(
    path.resolve(os.homedir(), ".cargo", "bin", "tauri-driver"),
    [],
    { stdio: [null, process.stdout, process.stderr] }
  );

  const capabilities = new Capabilities();
  capabilities.set("tauri:options", { application });
  capabilities.setBrowserName("wry");

  // start the webdriver client
  driver = await new Builder()
    .withCapabilities(capabilities)
    .usingServer("http://localhost:4444/")
    .build();
});

after(async function() {
  // stop the webdriver session
  await driver.quit();

  // kill the tauri-driver process
  tauriDriver.kill();
});

describe("AppFlowy Unit Test", () => {
  it("should find get started button", async () => {
    // should sign out if already sign in
    const getStartedButton = await driver.wait(until.elementLocated(By.xpath("//*[@id=\"root\"]/form/div/div[3]")));
    getStartedButton.click();
  });

  it("should get sign out button", async (done) => {
    // const optionButton = await driver.wait(until.elementLocated(By.css('*[test-id=option-button]')));
    // const optionButton = await driver.wait(until.elementLocated(By.id('option-button')));
    // const optionButton = await driver.wait(until.elementLocated(By.css('[aria-label=option]')));

    // Currently, only the find className is work
    const optionButton = await driver.wait(until.elementLocated(By.className("relative h-8 w-8")));
    optionButton.click();
    await new Promise((resolve) => setTimeout(resolve, 4000));
  });
});
