import { render, fireEvent } from '@testing-library/vue'
import Component from '../TimerClock.vue'
// import { Generate } from '@/utils/testsDataGenerator'

const startDate = new Date(2020, 3, 1, 10, 10)
const endDate = new Date(2020, 3, 1, 10, 30)

describe('components/TimerClock.vue', () => {
  test('set progress bar transform: translateX to -100% at start', async () => {
    const { getByRole } = render(Component, {
      props: {
        startDate,
        endDate
      }
    })

    const progressbar = getByRole('progressbar')

    expect(progressbar).toHaveStyle('transform: translateX(-100%)')
  })

  test('set progress bar label to 20 minutes at start', async () => {
    const { getByText } = render(Component, {
      props: {
        startDate,
        endDate
      }
    })

    const component = getByText('20 minutes left')

    expect(component).toBeVisible()
  })

  test('set progress bar aria attributes', async () => {
    const { getByRole } = render(Component, {
      props: {
        startDate,
        endDate
      }
    })

    const progressbar = getByRole('progressbar')
    expect(progressbar).toHaveAttribute('aria-valuenow', '0')
    expect(progressbar).toHaveAttribute('aria-valuemin', '0')
    expect(progressbar).toHaveAttribute('aria-valuemax', '100')
  })
})
