import { render, waitFor, fireEvent } from '@testing-library/vue'
import Component from '@/components/ContentBeforeBreak.vue'
import { Base } from '@/utils/tests/core'
const base = new Base(Component)
import { formatISO, addMinutes } from 'date-fns'
const mockDateIso = formatISO(addMinutes(new Date(), 15))

// jest.useFakeTimers()
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

const toWaitState = async (getByText: (text: string) => HTMLElement) => {
  jest.runAllTimers()
  const WaitButton = getByText('wait')
  await fireEvent.click(WaitButton)
  return WaitButton
}

describe('components/ContentBeforeBreak.vue', () => {
  test('has skip button', async () => {
    const { getByText, emitted } = base.render()
    const SkipButton = getByText('Skip break')
    expect(SkipButton).not.toBeVisible()
    await toWaitState(getByText)
    expect(SkipButton).toBeVisible()
    await fireEvent.click(SkipButton)
    expect(emitted().skip).toHaveLength(1)
  })

  test('has working progressbar', async () => {
    const { getByRole } = base.render()
    const Progressbar = getByRole('progressbar')
    expect(Progressbar).toBeVisible()
    expect(Progressbar).toHaveAttribute('aria-valuenow', '0')

    jest.runAllTimers()
    await waitFor(() =>
      expect(Progressbar).not.toHaveAttribute('aria-valuenow', '0')
    )
  })

  test('has working status text', async () => {
    const { getByText } = base.render()
    expect(
      getByText('Short break will start in 5 seconds', { exact: false })
    ).toBeVisible()

    await toWaitState(getByText)
    expect(
      getByText('Short break will start when you ready', { exact: false })
    ).toBeVisible()
  })

  test('has working wait and proceed button', async () => {
    const { getByText, emitted } = base.render()

    const WaitButton = await toWaitState(getByText)
    expect(emitted().wait).toHaveLength(1)

    await fireEvent.click(WaitButton)
    expect(emitted().break).toHaveLength(1)
  })
})
