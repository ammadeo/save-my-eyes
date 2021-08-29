import { isProdBuild } from './env'
import { join } from 'path'
import { app } from 'electron'
const appPath = () => {
  if (app) return app.getAppPath()
  throw new Error('path icon: no app instance')
}
export const appIcon = () =>
  isProdBuild
    ? join(appPath(), 'icon16x16.png')
    : join('public', 'icon16x16.png')
