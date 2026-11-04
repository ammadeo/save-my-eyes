import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/TimerInfo.vue'
import { Base } from '@/utils/tests/core'
import { formatISO, addMinutes } from 'date-fns'

const startDate = new Date(2020, 3, 1, 10, 10)
const endDate = new Date(2020, 3, 1, 10, 30)

const contentOptions = {
  long: 'take a long break for 20 minutes',
  short: 'take a short break for 20 minutes',
}

const base = new Base(Component, {
  props: {
    startDate,
    endDate,
  },
})
const mockDateIso = formatISO(addMinutes(new Date(), 15))

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
describe('components/TimerInfo.vue', () => {
  test('change content based on props', async () => {
    const { getByText, updateProps } = base.render()
    //? short break
    expect(getByText(contentOptions.short)).toBeVisible()
    //? long break
    await updateProps({
      long: true,
    })
    expect(getByText(contentOptions.long)).toBeVisible()
  })
})
