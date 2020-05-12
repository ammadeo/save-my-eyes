import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/IndexTimerButton.vue'

const contentOptions = {
  long: {
    default: 'Skip a long break',
    finished: 'Finish a long break',
  },
  short: {
    default: 'Skip for 5 minutes',
    finished: 'Finish a short break',
  },
}

describe('components/IndexTimerButton.vue', () => {
  test('on click emit click', async () => {
    const { getByText, emitted } = render(Component)
    const button = getByText(contentOptions.short.default)
    await fireEvent.click(button)
    expect(emitted().click).toBeTruthy()
  })

  test('change content based on props', async () => {
    const { getByText, updateProps } = render(Component)
    //? default
    expect(getByText(contentOptions.short.default)).toBeVisible()
    //? short finished
    await updateProps({
      long: false,
      finished: true,
    })
    expect(getByText(contentOptions.short.finished)).toBeVisible()
    //? long default
    await updateProps({
      long: true,
      finished: false,
    })
    expect(getByText(contentOptions.long.default)).toBeVisible()
    //? long finished
    await updateProps({
      long: true,
      finished: true,
    })
    expect(getByText(contentOptions.long.finished)).toBeVisible()
  })
})
