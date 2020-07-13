import { isProdBuild } from './env';
import { join } from 'path'

export const appIcon = isProdBuild
         ? join('resources', 'app.asar', 'icon.png')
         : join('public', 'icon.png')
