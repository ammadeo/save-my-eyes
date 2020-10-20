import { screen, BrowserWindow } from 'electron'
import { isProd, isProdBuild, isDevProdTest, debugProd } from './env'
import { createProtocol } from 'vue-cli-plugin-electron-builder/lib'
import { NewBreakOptions, setNewBreak } from './breaker'
import { appIcon } from './paths'
import { error } from 'electron-log'

export const backgroundDefault = '#121959'
export const backgroundTransparent = '#00000000'
export let rendererWindows: {
  [key: string]: BrowserWindow | undefined
  windowIndex: undefined | BrowserWindow
  windowTray: undefined | BrowserWindow
} = {
  windowIndex: undefined,
  windowTray: undefined,
}

export const closeAllWindows = () => {
  console.log('rendererWindows', rendererWindows)
  rendererWindows.windowIndex?.close()
  rendererWindows.windowTray?.close()

  rendererWindows = {
    windowIndex: undefined,
    windowTray: undefined,
  }
}

export const focusOn = (windowKey: keyof typeof rendererWindows) => {
  rendererWindows[windowKey]?.focus()
}

export const setBackgroundOf = (
  windowKey: keyof typeof rendererWindows,
  to: string = backgroundDefault
) => {
  rendererWindows[windowKey]?.setBackgroundColor(to)
}

const baseWindowSettings: () => Electron.BrowserWindowConstructorOptions = () => ({
  show: false,
  minimizable: !isProd,
  movable: !isProd,
  fullscreenable: !isProd,
  resizable: !isProd,
  alwaysOnTop: isProd,
  skipTaskbar: !debugProd && isProdBuild,
  frame: !isProd || debugProd,
  autoHideMenuBar: true,
  icon: appIcon(),
})

const getPrimaryDisplay = () => screen.getPrimaryDisplay().workAreaSize
const getExternalDisplays = (): Electron.Display[] => {
  const displays = screen.getAllDisplays()
  return displays.filter((display) => {
    return display.bounds.x !== 0 || display.bounds.y !== 0
  })
}

type WindowFunction = (window: BrowserWindow) => void

const createWindow = async (
  windowKey: keyof typeof rendererWindows,
  url: string,
  options: Electron.BrowserWindowConstructorOptions,
  extendWindow?: WindowFunction,
  showFocused = true,
  waitForURLLoad = true
) => {
  // Create the browser window.
  if (!rendererWindows[windowKey]) {
    const newWindow = new BrowserWindow({
      width: 800,
      height: 600,
      webPreferences: {
        nodeIntegration: true,
        devTools: debugProd || !isProdBuild,
      },
      ...options,
    })
    if (options.transparent) {
      newWindow.setIgnoreMouseEvents(true)
    }
    rendererWindows[windowKey] = newWindow
    if (process.env.WEBPACK_DEV_SERVER_URL) {
      // Load the url of the dev server if in development mode
      const path = (process.env.WEBPACK_DEV_SERVER_URL as string) + url
      try {
        if (waitForURLLoad) await newWindow.loadURL(path)
        else newWindow.loadURL(path)
      } catch (e) {
        error(e)
      }
      if (!isProd) newWindow.webContents.openDevTools()
    } else {
      createProtocol('app')
      // Load the index.html when not in development
      try {
        if (waitForURLLoad) await newWindow.loadURL(`app://./index.html/${url}`)
        else newWindow.loadURL(`app://./index.html/${url}`)
      } catch (e) {
        error(e)
      }
    }

    newWindow.on('closed', () => {
      rendererWindows[windowKey] = undefined
      if (windowKey === 'windowIndex') {
        // console.warn('warn', 'handling force close of index window, without prior new break set')
        setNewBreak({})
      }
    })

    if (extendWindow) extendWindow(newWindow)
  }

  if (showFocused) {
    rendererWindows[windowKey]?.show()
  } else {
    rendererWindows[windowKey]?.showInactive()
  }
}

interface CreateWindowIndexOptions {
  forceSkipBeforeBreakView?: NewBreakOptions['forceSkipBeforeBreakView']
}

const createWindowIndexChild = async (
  index: number,
  bounds: Electron.Rectangle
) => {
  const url = '/#/Blank'
  const { height, width, x, y } = bounds

  if (rendererWindows.windowIndex) {
    return await createWindow(`windowChild-${index}`, url, {
      width,
      height,
      y,
      x,
      backgroundColor: backgroundDefault,
      parent: rendererWindows.windowIndex,
      ...baseWindowSettings(),
    })
  }
}

export const createWindowIndexChildren = async () => {
  const externalDisplays = getExternalDisplays()
  try {
    await Promise.all(
      externalDisplays.map((display, index) => {
        return createWindowIndexChild(index, display.bounds)
      })
    )
  } catch (e) {
    console.error(e)
  }
}

export const createWindowIndex = async ({
  forceSkipBeforeBreakView,
}: CreateWindowIndexOptions) => {
  const url = forceSkipBeforeBreakView ? '/#/Index' : '/#/BeforeBreak'
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()
  try {
    await createWindow(
      'windowIndex',
      url,
      {
        width: screenWidth,
        height: screenHeight,
        y: 0,
        x: 0,
        backgroundColor: forceSkipBeforeBreakView
          ? backgroundDefault
          : backgroundTransparent,
        transparent: forceSkipBeforeBreakView ? false : isProd,
        ...baseWindowSettings(),
      },
      undefined,
      !!forceSkipBeforeBreakView,
      !!forceSkipBeforeBreakView
    )
  } catch (error) {
    console.error(error)
  }
  try {
    if (forceSkipBeforeBreakView) await createWindowIndexChildren()
  } catch (error) {
    console.error(error)
  }
}

export const createWindowTray = async () => {
  const url = '/#/Menu'
  const width = 500
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()
  const x = screenWidth - width
  try {
    return await createWindow(
      'windowTray',
      url,
      {
        width,
        height: screenHeight,
        y: 0,
        x,
        backgroundColor: backgroundTransparent,
        transparent: isProd && !debugProd,
        ...baseWindowSettings(),
      },
      undefined,
      undefined,
      false
    )
  } catch (error) {
    console.error(error)
  }
}
