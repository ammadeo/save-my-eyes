import { app, protocol, BrowserWindow } from 'electron'
import { installVueDevtools } from 'vue-cli-plugin-electron-builder/lib'
import { useTray } from '@/background/tray'
import { isProd, isProdBuild, isDevProdTest } from '@/background/env'
import { setNewBreak } from '@/background/breaker'
import { useIpcMain } from '@/background/ipc'
const isDevelopment = process.env.NODE_ENV !== 'production'

// Scheme must be registered before the app is ready
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { secure: true, standard: true } },
])

app.on('window-all-closed', (e: Event) => e.preventDefault())
app.setLoginItemSettings({
  openAtLogin: true,
})

app.on('ready', async () => {
  if (isDevelopment) {
    try {
      await installVueDevtools()
    } catch (e) {
      console.error('Vue Devtools failed to install:', e.toString())
    }
  }
  useIpcMain()

  //@ts-ignore
  app.tray = useTray()
  setNewBreak({})
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
