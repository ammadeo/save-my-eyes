import { screen, BrowserWindow } from 'electron'
import { isProd, isProdBuild, isDevProdTest } from './env'
import { createProtocol } from 'vue-cli-plugin-electron-builder/lib'
import { NewBreakOptions } from './breaker'
export const backgroundDefault = '#121959'
export const backgroundTransparent = '#00000000'
export const rendererWindows: {
  [key: string]: BrowserWindow | undefined
  windowIndex: undefined | BrowserWindow
  windowTray: undefined | BrowserWindow
} = {
  windowIndex: undefined,
  windowTray: undefined,
}

export const closeAllWindows = () => {
  rendererWindows.windowIndex?.close()
  rendererWindows.windowTray?.close()
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

const baseWindowSettings: Electron.BrowserWindowConstructorOptions = {
  show: false,
  minimizable: !isProd,
  movable: !isProd,
  fullscreenable: !isProd,
  resizable: !isProd,
  alwaysOnTop: isProd,
  skipTaskbar: isProd,
  frame: !isProd,
  autoHideMenuBar: true,
}

const getPrimaryDisplay = () => screen.getPrimaryDisplay().workAreaSize
const getExternalDisplays = (): Electron.Display[] => {
  const displays = screen.getAllDisplays()
  return displays.filter((display) => {
    return display.bounds.x !== 0 || display.bounds.y !== 0
  })
}

type WindowFunction = (window: BrowserWindow) => void

const createWindow = (
  windowKey: keyof typeof rendererWindows,
  url: string,
  options: Electron.BrowserWindowConstructorOptions,
  extendWindow?: WindowFunction,
  showFocused = true
) => {
  // Create the browser window.
  if (!rendererWindows[windowKey]) {
    const newWindow = new BrowserWindow({
      width: 800,
      height: 600,
      webPreferences: {
        nodeIntegration: true,
        devTools: true || !isProdBuild,
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
      newWindow.loadURL(path)
      if (!isProd) newWindow.webContents.openDevTools()
    } else {
      createProtocol('app')
      // Load the index.html when not in development
      newWindow.loadURL(`app://./index.html/${url}`)
    }

    newWindow.on('closed', () => {
      rendererWindows[windowKey] = undefined
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
  const url = '/#/blank'
  const { height, width, x, y } = bounds

  if (rendererWindows.windowIndex) {
    return createWindow(`windowChild-${index}`, url, {
      width,
      height,
      y,
      x,
      backgroundColor: backgroundDefault,
      parent: rendererWindows.windowIndex,
      ...baseWindowSettings,
    })
  }
}

export const createWindowIndexChildren = async () => {
  const externalDisplays = getExternalDisplays()
  return Promise.all(
    externalDisplays.map((display, index) => {
      return createWindowIndexChild(index, display.bounds)
    })
  )
}

export const createWindowIndex = async ({
  forceSkipBeforeBreakView,
}: CreateWindowIndexOptions) => {
  const url = forceSkipBeforeBreakView ? '/#/' : '/#/BeforeBreak'
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()

  createWindow(
    'windowIndex',
    url,
    {
      width: screenWidth,
      height: screenHeight,
      y: 0,
      x: 0,
      backgroundColor: backgroundTransparent,
      transparent: isProd,
      ...baseWindowSettings,
    },
    undefined,
    false
  )
  if (forceSkipBeforeBreakView) await createWindowIndexChildren()
}

export const createWindowTray = async () => {
  const url = '/#/menu'
  const width = 500
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()
  const x = screenWidth - width

  return createWindow('windowTray', url, {
    width,
    height: screenHeight,
    y: 0,
    x,
    backgroundColor: backgroundTransparent,
    transparent: isProd,
    ...baseWindowSettings,
  })
}


