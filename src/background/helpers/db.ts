// import { app, remote } from 'electron'
// import { join } from 'path'
// import { writeFileSync, readFileSync } from 'fs'
import * as Store from 'electron-store'

const userSettingsSchema = {
  breaks: {
    type: 'object',
    properties: {
      every: {
        type: 'number',
        minimum: 60,
        maximum: 60 * 60
      },
      short: {
        type: 'object',
        properties: {
          last: {
            type: 'number',
            minimum: 1,
            maximum: 60
          }
        }
      },
      long: {
        type: 'object',
        properties: {
          last: {
            type: 'number',
            minimum: 60,
            maximum: 60 * 60
          },
          every: {
            type: 'number',
            minimum: 1,
            maximum: 10
          }
        }
      }
    }
  },
  sounds: {
    type: 'object',
    properties: {
      ui: { type: 'boolean' },
      voice: { type: 'boolean' }
    }
  },
  lang: {
    type: 'string'
  }
}

const userSettingsDefaults = {
  breaks: {
    every: 15 * 60,
    short: {
      last: 30
    },
    long: {
      last: 5 * 60,
      every: 3
    }
  },
  sounds: {
    ui: true,
    voice: true
  },
  lang: ''
}

const userSettings = 'user-settings'

export const getUserSettingsStore = () =>
  new Store({
    schema: userSettingsSchema,
    defaults: userSettingsDefaults,
    name: userSettings
  })
