import { screen, BrowserWindow } from 'electron'
import { isProd, isProdBuild, isDevProdTest } from './env'
import { createProtocol } from 'vue-cli-plugin-electron-builder/lib'

let windowIndex: undefined | BrowserWindow,
  windowTray: undefined | BrowserWindow

const baseWindowSettings = {
  show: false,
  minimizable: !isProd,
  alwaysOnTop: isProd,
  skipTaskbar: isProd,
  frame: !isProd,
  autoHideMenuBar: true,
  devTools: true, //!isProd,
  webSecurity: isProd,
}

const getPrimaryDisplay = () => screen.getPrimaryDisplay().workAreaSize

function createWindow(
  window: undefined | BrowserWindow,
  url: string,
  options: Electron.BrowserWindowConstructorOptions
) {
  // Create the browser window.
  if (!window) {
    window = new BrowserWindow({
      width: 800,
      height: 600,
      webPreferences: {
        nodeIntegration: true
      },
      ...options
    })

    if (process.env.WEBPACK_DEV_SERVER_URL) {
      // Load the url of the dev server if in development mode
      const path = process.env.WEBPACK_DEV_SERVER_URL as string + url
      window.loadURL(path)
      if (!process.env.IS_TEST) window.webContents.openDevTools()
    } else {
      createProtocol('app')
      // Load the index.html when not in development
      window.loadURL(`app://${url}`)
    }

    window.on('closed', () => {
      window = undefined
    })
  }
  window.show()
}

export const createWindowIndex = async () => {
  const url = isProdBuild ? '-' : ''
  createWindow(windowIndex, url, {
    width: 1000,
    height: 600,
    fullscreen: isProd,
    ...baseWindowSettings
  })
}

export const createWindowTray = async () => {
  const url = isProdBuild ? './menu' : '/#/menu'
  const width = 600
  const {height: screenHeight, width: screenWidth} = getPrimaryDisplay();
  const x = screenWidth - width


  createWindow(windowTray, url, {
    width,
    height: screenHeight,
    y: 0,
    x,
    transparent: true,
    frame: false,
    ...baseWindowSettings,
  })
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
