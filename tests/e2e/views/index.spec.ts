// import { render, fireEvent } from '@testing-library/vue'
// import Page from '../index.vue'
// import { getUserSettingsStore } from '../../../main/helpers/db'
// import flushPromises from 'flush-promises'
// import { ipcRenderer } from 'electron-better-ipc'
// import { i18nStore as store } from '../../utils/testsVuexI18n'

// jest.mock('electron-better-ipc', () => ({
//   ipcRenderer: {
//     callMain: async (channel) => {
//       if (channel === 'set-break') {
//         return true
//       }
//       if (channel === 'break-count') {
//         return 1
//       }
//     }
//   }
// }))

// jest.mock('electron', () => ({
//   remote: {
//     getCurrentWindow: () => ({
//       close: jest.fn()
//     })
//   }
// }))

// const mockSettings = {
//   breaks: {
//     every: 15 * 60,
//     short: {
//       last: 30
//     },
//     long: {
//       last: 5 * 60,
//       every: 3
//     }
//   },
//   sounds: {
//     ui: true,
//     voice: true
//   }
// }

// jest.mock('../../../main/helpers/db')
// getUserSettingsStore.mockImplementation(() => ({
//   get: (id) => mockSettings[id]
// }))
// const mocks = {
//   $fetchState: {
//     pending: false,
//     error: false
//   }
// }
// const methods = {
//   close() {
//     //? skipped set closing
//     this.setNextBreak()
//     this.hideWindow()
//   },
//   finish: jest.fn()
// }

// describe('pages/index.vue', () => {
//   describe('mounted setup mocks', () => {
//     test('set correct start and end dates based on mock config', async () => {
//       const { getByText } = render(Page, { mocks, methods, store })
//       await flushPromises()
//       expect(getByText('Take a short break for 30 seconds')).toBeVisible()
//     })
//   })
//   describe('have nesesery components', () => {
//     test('has working counter', async () => {
//       const { getByText } = render(Page, { mocks, methods, store })
//       await flushPromises()
//       expect(getByText('30 seconds left')).toBeVisible()
//     })
//     test('has working close button', async () => {
//       const { getByText } = render(Page, { mocks, methods, store })
//       await flushPromises()
//       expect(getByText('Skip for 5 minutes')).toBeVisible()
//     })
//     test('has working settings card', async () => {
//       const { getByText } = render(Page, { mocks, methods, store })
//       await flushPromises()
//       expect(getByText('Settings')).toBeVisible()
//     })
//   })
//   describe('window closing', () => {
//     test.todo('prevent close on finished if prevented by autoFinishLock')
//     test.todo('close on finished if not prevented')
//     test.todo('send next break time before close')
//     test.todo('allow forced close even if prevented by autoFinishLock')
//   })
// })
