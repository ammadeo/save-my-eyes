import { app, protocol, BrowserWindow } from 'electron'
import installExtension, { VUEJS_DEVTOOLS } from 'electron-devtools-installer'
import { autoUpdater } from 'electron-updater'
import { info, verbose } from 'electron-log'
import path from 'path'

import { useTray } from '@/background/tray'
import { isProdBuild } from '@/background/env'
import { setNewBreak } from '@/background/breaker'
import { useIpcMain } from '@/background/ipc'

const appFolder = path.dirname(process.execPath)
const appPath = path.resolve(appFolder, 'save-my-eyes.exe')
let tray: Electron.Tray | undefined
// Scheme must be registered before the app is ready
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { secure: true, standard: true } },
])

app.on('window-all-closed', (e: Event) => e.preventDefault())

app.on('ready', async () => {
  info('app ready event fired')
  if (!isProdBuild) {
    try {
      await installExtension(VUEJS_DEVTOOLS)
    } catch (e) {
      console.error('Vue Devtools failed to install:', e.toString())
    }
  }

  if (
    !app.getLoginItemSettings({
      path: appPath,
    }).openAtLogin
  ) {
    app.setLoginItemSettings({
      openAtLogin: true,
      path: appPath,
    })
    info('app registered to start on login')
  } else {
    if (!isProdBuild) verbose('not: app registered to start on login')
  }

  useIpcMain()
  if (!isProdBuild) verbose('app using IPC main module')
  tray = useTray()
  if (!isProdBuild) verbose('app using Tray module')
  setNewBreak({})
  if (!isProdBuild) verbose('app break set')
  if (!isProdBuild) verbose('app ended init process')
  if (isProdBuild) {
    autoUpdater.checkForUpdatesAndNotify()
  }
})

// Exit cleanly on request from parent process in development mode.
if (!isProdBuild) {
  if (process.platform === 'win32') {
    process.on('message', (data) => {
      if (data === 'graceful-exit') {
        app.quit()
      }
    })
  } else {
    process.on('SIGTERM', () => {
      app.quit()
    })
  }
}
