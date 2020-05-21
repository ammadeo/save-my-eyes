import { render, fireEvent, waitFor } from '@testing-library/vue'
import Component from '@/components/ContentMenu.vue'
import { Generate } from '@/utils/tests/dataGenerator'
import { formatISO, addMinutes } from 'date-fns'
const mockDateIso = formatISO(addMinutes(new Date(), 15))

jest.mock('vue-cli-plugin-electron-builder/lib', () => ({
  createProtocol: () => {},
}))
jest.mock('@/background/ipc', () => ({
  rendererGetBreakData: {
    ask: async () =>
      new Promise((resolve) =>
        resolve({
          lastSchedulerJobDate: mockDateIso,
          lastSchedulerJobLength: 5 * 60,
        })
      ),
  },
}))
jest.mock('@/background/db', () => ({
  getUserSettingsStore: () => ({
    get: () => ({
      every: 15 * 60,
      short: {
        last: 30,
      },
      long: {
        every: 3,
        last: 5 * 60,
      },
    }),
  }),
}))

describe('components/ContentMenu.vue', () => {
  test('has next break time info', async () => {
    const { getByText } = render(Component)
    await waitFor(() => {
      const ContentBox = getByText('next short break in')
      expect(ContentBox).toBeVisible()
      const SpanBox = getByText('19 minutes')
      expect(SpanBox).toBeVisible()
    })
  })

  test('has start a long break now button', async () => {
    const { getByText, emitted } = render(Component)

    const Button = getByText('start a long break now', { exact: false })
    expect(Button).toBeVisible()
    await fireEvent.click(Button)
    expect(emitted().run[0]).toStrictEqual(['start-long-break'])
  })

  test('has stop protection button', async () => {
    const { getByText, emitted } = render(Component)

    const Button = getByText('stop protection', { exact: false })
    expect(Button).toBeVisible()
    await fireEvent.click(Button)
    expect(emitted().run[0]).toStrictEqual(['open-stop-protection'])
  })

  test('has settings button', async () => {
    const { getByText, emitted } = render(Component)

    const Button = getByText('settings', { exact: false })
    expect(Button).toBeVisible()
    await fireEvent.click(Button)
    expect(emitted().run[0]).toStrictEqual(['open-settings'])
  })
})
