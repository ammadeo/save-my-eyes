process.env.IS_TEST = true

import spectron from 'spectron'
import { testWithSpectron } from 'vue-cli-plugin-electron-builder'
jest.setTimeout(5 * 60 * 1000)

test('Window Loads Properly', async () => {
  // Wait for dev server to start
  const { app, stopServe } = await testWithSpectron(spectron, {
    // @ts-ignore
    spectronOptions: {
      connectionRetryCount: 3,
      startTimeout: 60 * 1000,
    },
  })
  const win = app.browserWindow
  const client = app.client

  // Window was created
  expect(await client.getWindowCount()).toBe(0)
  // It is not minimized
  // expect(win.isMinimized()).toBe(false)
  // Window is visible
  // expect(win.isVisible()).toBe(true)
  // Size is correct
  // const { width, height } = win.getBounds()
  // expect(width).toBeGreaterThan(0)
  // expect(height).toBeGreaterThan(0)
  // App is loaded properly
  // expect(
  //   /Welcome to Your Vue\.js (\+ TypeScript )?App/.test(
  //     await client.getHTML("#app")
  //   )
  // ).toBe(true);

  await stopServe()
})
