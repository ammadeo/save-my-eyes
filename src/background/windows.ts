import { screen, BrowserWindow } from 'electron'
import { isProd, isProdBuild, isDevProdTest } from './env'
import { createProtocol } from 'vue-cli-plugin-electron-builder/lib'

const windows: {
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
  alwaysOnTop: isProd,
  skipTaskbar: isProd,
  frame: !isProd,
  autoHideMenuBar: true
}

const getPrimaryDisplay = () => screen.getPrimaryDisplay().workAreaSize

type WindowFunction = (window: BrowserWindow) => void

function createWindow(
  windowKey: keyof typeof windows,
  url: string,
  options: Electron.BrowserWindowConstructorOptions,
  extendWindow?: WindowFunction
) {
  // Create the browser window.
  if (!windows[windowKey]) {
    const newWindow = new BrowserWindow({
      width: 800,
      height: 600,
      webPreferences: {
        nodeIntegration: true,
        devTools: !isProdBuild,
      },
      ...options,
    })
    windows[windowKey] = newWindow
    if (process.env.WEBPACK_DEV_SERVER_URL) {
      // Load the url of the dev server if in development mode
      const path = (process.env.WEBPACK_DEV_SERVER_URL as string) + url
      newWindow.loadURL(path)
      if (!process.env.IS_TEST) newWindow.webContents.openDevTools()
    } else {
      createProtocol('app')
      // Load the index.html when not in development
      newWindow.loadURL(`app://${url}`)
    }

    newWindow.on('closed', () => {
      windows[windowKey] = undefined
    })

    if (extendWindow) extendWindow(newWindow)
  }
  windows[windowKey]?.show()
}

export const createWindowIndex = async () => {
  const url = isProdBuild ? '-' : ''
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()

  createWindow('windowIndex', url, {
    width: screenWidth,
    height: screenHeight,
    y: 0,
    x: 0,
    ...baseWindowSettings,
  })
}

export const createWindowTray = async () => {
  const url = isProdBuild ? './menu' : '/#/menu'
  const width = 500
  const { height: screenHeight, width: screenWidth } = getPrimaryDisplay()
  const x = screenWidth - width

  createWindow(
    'windowTray',
    url,
    {
      width,
      height: screenHeight,
      y: 0,
      x,
      backgroundColor: '#00000000',
      transparent: true,
      ...baseWindowSettings,
    },
    (window) => {
      window.on('blur', () => {
        window.close()
      })
    }
  )
}

// const createWindow = (options) => {
// const key = 'window-state'
// const defaultSize = {
//   width: options.width,
//   height: options.height,
// }
// let state = {}
// let win

// const getCurrentPosition = () => {
//   const position = win.getPosition()
//   const size = win.getSize()
//   return {
//     x: position[0],
//     y: position[1],
//     width: size[0],
//     height: size[1],
//   }
// }

// const windowWithinBounds = (windowState, bounds) => {
//   return (
//     windowState.x >= bounds.x &&
//     windowState.y >= bounds.y &&
//     windowState.x + windowState.width <= bounds.x + bounds.width &&
//     windowState.y + windowState.height <= bounds.y + bounds.height
//   )
// }

// const resetToDefaults = () => {
//   const bounds = screen.getPrimaryDisplay().bounds
//   return Object.assign({}, defaultSize, {
//     x: (bounds.width - defaultSize.width) / 2,
//     y: (bounds.height - defaultSize.height) / 2,
//   })
// }

// const ensureVisibleOnSomeDisplay = (windowState) => {
//   const visible = screen.getAllDisplays().some((display) => {
//     return windowWithinBounds(windowState, display.bounds)
//   })
//   if (!visible) {
//     // Window is partially or fully not visible now.
//     // Reset it to safe defaults.
//     return resetToDefaults()
//   }
//   return windowState
// }

//   const win = new BrowserWindow({
//     ...options,
//     // ...state,
//     webPreferences: {
//       nodeIntegration: true
//     }
//   })

//   return win
// }
