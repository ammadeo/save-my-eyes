import { render, fireEvent, waitFor } from '@testing-library/vue'
import Component from '@/components/TimerClock.vue'
import { Base } from '@/utils/tests/core'
import { formatISO, addMinutes } from 'date-fns'
const mockDateIso = formatISO(addMinutes(new Date(), 15))
jest.useFakeTimers()

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

const startDate = new Date(2020, 3, 1, 10, 10)
const endDate = new Date(2020, 3, 1, 10, 30)
const base = new Base(Component, {
  props: {
    startDate,
    endDate,
  },
})

describe('components/TimerClock.vue', () => {
  test('has working progressbar', async () => {
    const { getByRole, debug } = base.render()
    const Progressbar = getByRole('progressbar')
    expect(Progressbar).toBeVisible()
    const ProgressDrawer = [...Progressbar.children][0]
    expect(ProgressDrawer).toHaveStyle('transform: translateX(-100%)')
    jest.runAllTimers()
    await waitFor(() =>
      expect(ProgressDrawer).not.toHaveStyle('transform: translateX(-100%)')
    )
  })

  test('set progress bar label for 20 minutes at start to 20 : 01', async () => {
    const { getByText } = base.render()

    const component = getByText('20 : 01')

    expect(component).toBeVisible()
  })

  test('set progress bar aria attributes', async () => {
    const { getByRole } = base.render()

    const progressbar = getByRole('progressbar')
    expect(progressbar).toHaveAttribute('aria-valuenow', '0')
    expect(progressbar).toHaveAttribute('aria-valuemin', '0')
    expect(progressbar).toHaveAttribute('aria-valuemax', '100')
  })
})
