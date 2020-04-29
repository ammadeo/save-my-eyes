import { scheduleJob, Job } from 'node-schedule'
import { addSeconds } from 'date-fns'
import { isProd, isProdBuild, isDevProdTest } from './env'
import { createWindowIndex } from './windows'
import { breakIndex } from './store'
import { getUserSettingsStore } from './db'
// import log from 'electron-log'

let breakSchedule: Job | undefined

const getEveryFromDB = () => {
  return getUserSettingsStore().get('breaks').every
}

const calculateNextBreak = (nextBreakIn: number) => {
  return addSeconds(new Date(), isProdBuild ? nextBreakIn : 3)
}

export const setNewBreak = (forceBreakIn?: number) => {
  const forced = !!forceBreakIn
  const nextBreakIn = forceBreakIn || getEveryFromDB()

  const nextBreak = calculateNextBreak(nextBreakIn)

  if (!forced) breakIndex.value++
  const keyBreakIndex = breakIndex.value
  if (breakSchedule) breakSchedule.cancel()
  console.log(
    'setNewBreak',
    'keyBreakIndex',
    keyBreakIndex,
    'breakIndex.value',
    breakIndex.value,
    'forced',
    forced,
    'nextBreak',
    nextBreak,
    'nextBreakIn',
    nextBreakIn
  )
  breakSchedule = scheduleJob(nextBreak, () => {
    if (keyBreakIndex === breakIndex.value) {
      createWindowIndex()
    }
  })
}
