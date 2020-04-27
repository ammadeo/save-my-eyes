import { screen, BrowserWindow } from 'electron'
import { isProd, isProdBuild, isDevProdTest } from './env'

let windowIndex, windowTray

const baseWindowSettings = {
  show: false,
  minimizable: !isProd,
  alwaysOnTop: isProd,
  skipTaskbar: isProd,
  frame: !isProd,
  autoHideMenuBar: true,
  devTools: true, //!isProd,
  webSecurity: false //isProd,
}

export const createWindowIndex = async () => {
  if (!windowIndex) {
    windowIndex = createWindow({
      width: 1000,
      height: 600,
      fullscreen: isProd,
      ...baseWindowSettings
    })
    windowIndex.on('close', () => {
      windowIndex = undefined
    })
    if (isProdBuild) {
      await windowIndex.loadURL('app://-')
    } else {
      const port = process.argv[2]
      await windowIndex.loadURL(`http://localhost:${port}`)
      windowIndex.webContents.openDevTools()
    }
  }
  windowIndex.show()
}

export const createWindowTray = async () => {
  if (!windowTray) {
    windowTray = createWindow({
      width: 600,
      height: 300,
      ...baseWindowSettings
    })
    windowTray.on('close', () => {
      windowTray = undefined
    })
    if (isProdBuild) {
      await windowTray.loadURL('app://tray')
    } else {
      const port = process.argv[2]
      await windowTray.loadURL(`http://localhost:${port}/tray`)
      // mainWindow.webContents.openDevTools()
    }
  }
  windowTray.show()
}

const createWindow = (options) => {
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

  const win = new BrowserWindow({
    ...options,
    // ...state,
    webPreferences: {
      nodeIntegration: true
    }
  })

  return win
}
