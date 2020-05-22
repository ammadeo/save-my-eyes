import { screen, BrowserWindow } from 'electron'
import { isProd, isProdBuild, isDevProdTest } from './env'
import { createProtocol } from 'vue-cli-plugin-electron-builder/lib'

const windows: {
  [key: string]: BrowserWindow | undefined
  windowIndex: undefined | BrowserWindow
  windowTray: undefined | BrowserWindow
} = {
  windowIndex: undefined,
  windowTray: undefined,
}

export const closeAllWindows = () => {
  windows.windowIndex?.close()
  windows.windowTray?.close()
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
  let displays = screen.getAllDisplays()
  return displays.filter((display) => {
    return display.bounds.x !== 0 || display.bounds.y !== 0
  })
}

type WindowFunction = (window: BrowserWindow) => void



export const createWindowIndex = async () => {
  const url = '/#/BeforeBreak'
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()

  createWindow('windowIndex', url, {
    width: screenWidth,
    height: screenHeight,
    y: 0,
    x: 0,
    backgroundColor: '#00000000',
    transparent: isProd,
    ...baseWindowSettings,
  }, undefined, false)
}

export const createWindowTray = async () => {
  const url = '/#/menu'
  const width = 500
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()
  const x = screenWidth - width

  createWindow('windowTray', url, {
    width,
    height: screenHeight,
    y: 0,
    x,
    backgroundColor: '#00000000',
    transparent: isProd,
    ...baseWindowSettings,
  })
}

const createWindowIndexChild = async (
  index: number,
  bounds: Electron.Rectangle
) => {
  const url = '/#/blank'
  const { height, width, x, y } = bounds

  createWindow(`windowChild-${index}`, url, {
    width,
    height,
    y,
    x,
    backgroundColor: '#121959',
    parent: windows.windowIndex,
    ...baseWindowSettings,
  })
}

export const createWindowIndexChildren = async () => {
  const externalDisplays = getExternalDisplays()
  externalDisplays.forEach((display, index) => {
    createWindowIndexChild(index, display.bounds)
  })
}

const createWindow = async (
  windowKey: keyof typeof windows,
  url: string,
  options: Electron.BrowserWindowConstructorOptions,
  extendWindow?: WindowFunction,
  showFocused = true
) => {
  // Create the browser window.
  if (!windows[windowKey]) {
    const newWindow = new BrowserWindow({
      width: 800,
      height: 600,
      webPreferences: {
        nodeIntegration: true,
        devTools: true || !isProdBuild,
      },
      ...options,
    })
    windows[windowKey] = newWindow
    if (process.env.WEBPACK_DEV_SERVER_URL) {
      // Load the url of the dev server if in development mode
      const path = (process.env.WEBPACK_DEV_SERVER_URL as string) + url
      await newWindow.loadURL(path)
      newWindow.webContents.openDevTools()
    } else {
      createProtocol('app')
      // Load the index.html when not in development
      await newWindow.loadURL(`app://./index.html/${url}`)
    }

    newWindow.on('closed', () => {
      windows[windowKey] = undefined
    })

    if (extendWindow) extendWindow(newWindow)
  }
  if (showFocused) {
    windows[windowKey]?.show()
  } else {
    windows[windowKey]?.showInactive()
  }
}

