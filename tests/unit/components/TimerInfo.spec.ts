import { render, fireEvent } from '@testing-library/vue'
import Component from '../TimerInfo.vue'

const startDate = new Date(2020, 3, 1, 10, 10)
const endDate = new Date(2020, 3, 1, 10, 30)

const contentOptions = {
  long: 'Take a long break for 20 minutes',
  short: 'Take a short break for 20 minutes',
}

describe('components/TimerInfo.vue', () => {
  test('change content based on props', async () => {
    const { getByText, updateProps } = render(Component, {
      props: {
        startDate,
        endDate,
      },
    })
    //? short break
    expect(getByText(contentOptions.short)).toBeVisible()
    //? long break
    await updateProps({
      long: true,
    })
    expect(getByText(contentOptions.long)).toBeVisible()
  })
})
