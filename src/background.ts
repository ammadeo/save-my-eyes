import { app, protocol, BrowserWindow } from 'electron'
import { installVueDevtools } from 'vue-cli-plugin-electron-builder/lib'
import { useTray } from '@/background/tray'
import { isProd, isProdBuild, isDevProdTest } from '@/background/env'
import { setNewBreak } from '@/background/breaker'
import { useIpcMain } from '@/background/ipc'
import { info, verbose } from 'electron-log'
import path from 'path'
const isDevelopment = process.env.NODE_ENV !== 'production'
const appFolder = path.dirname(process.execPath)
const appPath = path.resolve(appFolder, 'save-my-eyes.exe')
let tray: Electron.Tray
// Scheme must be registered before the app is ready
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { secure: true, standard: true } },
])

app.on('window-all-closed', (e: Event) => e.preventDefault())

app.on('ready', async () => {
  verbose('app ready event fired')
  if (isDevelopment) {
    try {
      await installVueDevtools()
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
    verbose('not: app registered to start on login')
  }

  useIpcMain()
  verbose('app using IPC main module')
  tray = useTray()
  verbose('app using Tray module')
  setNewBreak({})
  verbose('app break set')
  verbose('app ended init process')
})

// Exit cleanly on request from parent process in development mode.
if (isDevelopment) {
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
