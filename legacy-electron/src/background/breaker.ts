import { scheduleJob, Job } from 'node-schedule'
import { addSeconds } from 'date-fns'
import { isProdBuild, isDevProdTest } from './env'
import { createWindowIndex, closeAllWindows } from './windows'
import {
  breakIndex,
  breakId,
  lastSchedulerJobDate,
  lastSchedulerJobLength,
} from './store'
import { getUserSettingsStore } from './db'

let breakSchedule: Job | undefined

const getEveryFromDB = () => {
  return getUserSettingsStore().get('breaks').every
}

const calculateNextBreak = (nextBreakIn: number) => {
  return addSeconds(
    new Date(),
    isProdBuild ? nextBreakIn : isDevProdTest ? 60 : 5
  )
}

export interface NewBreakOptions {
  forceNextBreakIn?: number
  forceNextBreakType?: 'long' | 'short'
  forceSkipBeforeBreakView?: true
  preventImmediateWindowClosing?: true
  preventChangingIndex?: true
}

class NewBreakIndex {
  constructor(
    private readonly oldIndex: number,
    private readonly options: NewBreakOptions
  ) {}
  public get = () => {
    return this.getForcedType() ?? this.getPreserve() ?? this.getDefault()
  }

  private getForcedType = () => {
    const forceNextBreakType = this.options?.forceNextBreakType
    if (forceNextBreakType) {
      const forceLongBreak = forceNextBreakType === 'long'
      if (forceLongBreak) {
        return getUserSettingsStore().get('breaks').long.every
      } else {
        return 1
      }
    }
  }

  private getPreserve = () => {
    const preserve = !!this.options.preventChangingIndex
    if (preserve) return this.oldIndex
  }

  private getDefault = () => {
    return this.oldIndex + 1
  }
}

export const setNewBreak = async (options: NewBreakOptions) => {
  if (!options.preventImmediateWindowClosing) closeAllWindows()

  const nextBreakIn = options?.forceNextBreakIn ?? getEveryFromDB()

  breakIndex.value = new NewBreakIndex(breakIndex.value, options).get()

  breakId.value++
  const keyBreakId = breakId.value

  if (breakSchedule) breakSchedule.cancel()

  console.log('setNewBreak', 'breakIndex.value', breakIndex.value)

  lastSchedulerJobDate.value = new Date().toISOString()
  lastSchedulerJobLength.value = nextBreakIn
  console.log(
    'nextBreakIn',
    nextBreakIn,
    'lastSchedulerJobLength.value',
    lastSchedulerJobLength.value
  )
  const { forceSkipBeforeBreakView } = options
  if (nextBreakIn > 0) {
    const nextBreak = calculateNextBreak(nextBreakIn)

    breakSchedule = scheduleJob(nextBreak, async () => {
      if (keyBreakId === breakId.value) {
        closeAllWindows()
        await createWindowIndex({ forceSkipBeforeBreakView })
      }
    })
  } else {
    if (!options.preventImmediateWindowClosing) closeAllWindows()
    await createWindowIndex({ forceSkipBeforeBreakView })
  }
}

//? no need for this check for now
// export const isBreakSet = () => {
//   const now = new Date()
//   const breakStart = addSeconds(
//     parseISO(lastSchedulerJobDate.value),
//     lastSchedulerJobLength.value
//   )
//   return now.getTime() <= breakStart.getTime()
// }
