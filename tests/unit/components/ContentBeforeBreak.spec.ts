import { render, waitFor } from '@testing-library/vue'
import Component from '@/components/ContentBeforeBreak.vue'
import { Base } from '@/utils/tests/core'
const base = new Base(Component)
import { formatISO, addMinutes } from 'date-fns'
const mockDateIso = formatISO(addMinutes(new Date(), 15))

jest.useFakeTimers()
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

describe('components/ContentBeforeBreak.vue', () => {
  test('has skip button', () => {
    const { getByText } = base.render()
    expect(getByText('Skip for 5 minutes')).toBeVisible()
  })

  test('has working progressbar', async () => {
    const { getByRole } = base.render()
    const Progressbar = getByRole('progressbar')
    expect(Progressbar).toBeVisible()
    const ProgressDrawer = [...Progressbar.children][1]
    expect(ProgressDrawer).toHaveStyle('transform: translateX(-100%)')
    jest.runAllTimers()
    await waitFor(() =>
      expect(ProgressDrawer).not.toHaveStyle('transform: translateX(-100%)')
    )
  })
})
