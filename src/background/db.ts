import Store from 'electron-store'
import { Languages } from '@/store/i18n'
import {isProdBuild } from './env'
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
        minimum: 60,
        maximum: 60 * 60,
      },
      short: {
        type: 'object',
        properties: {
          last: {
            type: 'number',
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
            minimum: 60,
            maximum: 60 * 60,
          },
          every: {
            type: 'number',
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
      ui: { type: 'boolean'},
      voice: { type: 'boolean'},
    },
  },
  lang: {
    type: 'string',
  },
}

const userSettingsDefaults = {
  breaks: {
    every: 15 * 60,
    short: {
      last: 30,
    },
    long: {
      last: 5 * 60,
      every: 3,
    },
  },
  sounds: {
    ui: true,
    voice: true,
  },
  lang: 'en' as Languages,
}

const userSettings = isProdBuild ? 'user-settings' : 'user-settings-dev'

export const getUserSettingsStore = () =>
  new Store<TypedStore>({
    schema: userSettingsSchema,
    defaults: userSettingsDefaults,
    name: userSettings,
  })
