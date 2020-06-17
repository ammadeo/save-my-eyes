import Store from 'electron-store'
import { Languages } from '@/store/i18n'

interface TypedStore {
  breaks: {
    every: number
    short: {
      last: number
    }
    long: {
      last: number
      every: number
    }
  }

  sounds: {
    ui: boolean
    voice: boolean
  }
  lang: Languages
}

interface UserSettingsSchema {
  breaks: Store.Schema
  sounds: Store.Schema
  lang: Store.Schema
}

const userSettingsSchema: UserSettingsSchema = {
  breaks: {
    type: 'object',
    properties: {
      every: {
        type: 'number',
        default: 15 * 60,
        minimum: 60,
        maximum: 60 * 60,
      },
      short: {
        type: 'object',
        properties: {
          last: {
            type: 'number',
            default: 30,
            minimum: 1,
            maximum: 60,
          },
        },
      },
      long: {
        type: 'object',
        properties: {
          last: {
            type: 'number',
            default: 5 * 60,
            minimum: 60,
            maximum: 60 * 60,
          },
          every: {
            type: 'number',
            default: 3,
            minimum: 1,
            maximum: 10,
          },
        },
      },
    },
  },
  sounds: {
    type: 'object',
    properties: {
      ui: { type: 'boolean', default: true },
      voice: { type: 'boolean', default: true },
    },
  },
  lang: {
    type: 'string',
    default: 'en',
  },
}

// const userSettingsDefaults = {
//   breaks: {
//     every: 15 * 60,
//     short: {
//       last: 30,
//     },
//     long: {
//       last: 5 * 60,
//       every: 3,
//     },
//   },
//   sounds: {
//     ui: true,
//     voice: true,
//   },
//   lang: 'en',
// }

const userSettings = 'user-settings'

export const getUserSettingsStore = () =>
  new Store<TypedStore>({
    schema: userSettingsSchema,
    // defaults: userSettingsDefaults,
    name: userSettings,
  })
