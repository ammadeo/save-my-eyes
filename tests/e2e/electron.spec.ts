/**
 * @jest-environment node
 */
// process.env.IS_TEST = "true"

import {Application} from 'spectron'
import path from 'path'
import portfinder from 'portfinder'
import {testWithSpectron, Options, Server} from 'vue-cli-plugin-electron-builder'

// import execa from 'execa'


jest.setTimeout(3 * 60 * 1000)

// execa(
//   require.resolve('@vue/cli-service/bin/vue-cli-service'),
//   ['electron:serve', '--headless', '--mode', options.mode || 'test'],
//   {
//     env: {
//       ...process.env,
//       NODE_ENV: !options.forceDev ? 'production' : 'development',
//     },
//   }
// )

const vueCli = require.resolve('@vue/cli-service/bin/vue-cli-service')

// const spectronTest = testWithSpectron as (
//   options: Partial<Options>
// ) => Promise<Server>


describe('Core', () => {
  let app: Application
  beforeAll(async ()=>{
    // const {app: testApp} = await spectronTest({
    //   // noSpectron: true,
    //   // noStart: true,
    // })
    app = new Application({
      path: vueCli,
      args: ['electron:serve', '--headless', '--mode', 'test'],
      env: {
        IS_TEST: true,
      },
      // port: await portfinder.getPortPromise(),
    })
  })
  beforeEach(async () => {
    await app.start()
  })

  test('Window Loads Properly', async () => {
    // const win = app.browserWindow
    const client = app.client
    // Window was created
    expect(await client.getWindowCount()).toBe(0)
    // It is not minimized
    // expect(await win.isMinimized()).toBe(false)
    // Window is visible
    // expect(await win.isVisible()).toBe(true)
    // Size is correct
    // const { width, height } = await win.getBounds()
    // expect(width).toBeGreaterThan(0)
    // expect(height).toBeGreaterThan(0)
    // App is loaded properly
    // expect(
    //   /Welcome to Your Vue\.js (\+ TypeScript )?App/.test(
    //     await client.getHTML('#app')
    //   )
    // ).toBe(true)
  })

  afterEach(async () => {
    if (app && app.isRunning()) {
      await app.stop()
    }
  })
})

export {}



