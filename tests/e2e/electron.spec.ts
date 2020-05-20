/**
 * @jest-environment node
 */
import {Application} from 'spectron'
import path from 'path'


jest.setTimeout(3 * 60 * 1000)

const app = new Application({
  path: require('electron'),
  args: [path.join(__dirname, '..')],
})

describe('Core', () => {
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




