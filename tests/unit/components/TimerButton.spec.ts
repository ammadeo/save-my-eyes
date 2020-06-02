import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/IndexTimerButton.vue'

const contentOptions = {
  long: {
    default: 'Skip long break',
    finished: 'Finish long break',
  },
  short: {
    default: 'Skip short break',
    finished: 'Finish short break',
  },
}

jest.useFakeTimers()

describe('components/IndexTimerButton.vue', () => {
  test('on click emit click', async () => {
    const { getByText, emitted } = render(Component)
    const button = getByText(contentOptions.short.default)
    await fireEvent.click(button)
    jest.runAllTimers()
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
