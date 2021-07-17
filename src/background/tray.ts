import { Tray } from 'electron'
import { isProdBuild } from './env'
import { createWindowTray } from './windows'
import { getUserSettingsStore, TypedStore } from './db'
import { formatDistanceStrict, addSeconds } from 'date-fns'
import { pl, enGB } from 'date-fns/locale'
import ElectronStore from 'electron-store'
import { appIcon } from './paths'
import { debug, verbose, error } from 'electron-log'
import { existsSync } from 'fs'

const getNextBreakIn = (store: ElectronStore<TypedStore>) => {
  const every = store.get('breaks').every
  if (!isProdBuild) debug('tray balloon get breaks every', every)
  const now = new Date()
  return formatDistanceStrict(now, addSeconds(now, every), {
    roundingMethod: 'floor',
    locale: store.get('lang') === 'en' ? enGB : pl,
  })
}

const generateBalloonContent = () => {
  const store = getUserSettingsStore()
  if (!isProdBuild) debug('tray balloon receive store')
  const nextBreakIn = getNextBreakIn(store)
  if (!isProdBuild) debug('tray balloon next break in', nextBreakIn)
  if (!isProdBuild) debug('tray balloon get lang', store.get('lang'))
  return store.get('lang') === 'en'
    ? `Your eyes are protected. Next break will start in ${nextBreakIn}. Click on icon below to find out more`
    : `Dbamy o Twoje oczy. Następna przerwa rozpocznie się za ${nextBreakIn}. Kliknij ikonę poniżej, aby dowiedzieć się więcej`
}

const openMenu = async () => {
  if (!isProdBuild) debug('tray: open menu init')

  try {
    await createWindowTray()
    if (!isProdBuild) debug('tray: open menu success')
  } catch (e) {
    error('tray: open menu error', e)
  }
}

export const useTray = () => {
  if (!isProdBuild) verbose('tray starting to init')
  if (!isProdBuild) debug('tray icon path', appIcon)
  if (!isProdBuild) debug('tray icon exists', existsSync(appIcon()))
  let tray: Tray
  try {
    tray = new Tray(appIcon())
    if (!isProdBuild) debug('tray created')
    tray.setToolTip(
      isProdBuild ? 'Save your eyes' : 'Save your eyes (Development)'
    )
    if (!isProdBuild) debug('tray set tooltip')
    tray.on('click', openMenu)
    tray.on('right-click', openMenu)
    if (!isProdBuild) debug('tray set click handlers')
    tray.displayBalloon({
      icon: appIcon(),
      title: 'Save My Eyes',
      content: generateBalloonContent(),
    })
    if (!isProdBuild) debug('tray displayed balloon')
    return tray
  } catch (e) {
    error('tray error', e)
  }
  return undefined
}
