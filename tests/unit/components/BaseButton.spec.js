import { render, fireEvent } from '@testing-library/vue'
import Component from '../BaseButton.vue'
import { Generate } from '@/utils/testsDataGenerator'

const pTagText = Generate.string()
const pTag = `<p>${pTagText}</p>`

describe('components/BaseButton.vue', () => {
  test('has content slot', async () => {
    const { getByText } = render(Component, {
      slots: {
        default: pTag,
      },
    })

    const progressbar = getByText(pTagText)

    expect(progressbar).toBeVisible()
  })
  test('on click emit click', async () => {
    const { getByText, emitted } = render(Component, {
      slots: {
        default: pTagText,
      },
    })
    const button = getByText(pTagText)
    await fireEvent.click(button)
    expect(emitted().click).toBeTruthy()
  })
  test('set secondary color classes on primary prop', async () => {
    const { getByText, updateProps } = render(Component, {
      slots: {
        default: pTagText,
      },
    })
    expect(getByText(pTagText)).toHaveClass('bg-secondary-700')
    expect(getByText(pTagText)).toHaveClass('hover:bg-secondary-800')
    expect(getByText(pTagText)).toHaveClass('focus:bg-secondary-800')
    await updateProps({ primary: true })
    expect(getByText(pTagText)).toHaveClass('bg-primary-700')
    expect(getByText(pTagText)).toHaveClass('hover:bg-primary-800')
    expect(getByText(pTagText)).toHaveClass('focus:bg-primary-800')
  })
})
