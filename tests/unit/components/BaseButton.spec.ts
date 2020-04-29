import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/BaseButton.vue'
import { Generate } from '@/utils/testsDataGenerator'

const pTagText = Generate.string()
const pTag = `<p>${pTagText}</p>`

describe('components/BaseButton.vue', () => {
  test('has content slot', async () => {
    const { getByText } = render(Component, {
      slots: {
        default: pTag
      }
    })

    const progressbar = getByText(pTagText)

    expect(progressbar).toBeVisible()
  })
  test('on click emit click', async () => {
    const { getByText, emitted } = render(Component, {
      slots: {
        default: pTagText
      }
    })
    const button = getByText(pTagText)
    await fireEvent.click(button)
    expect(emitted().click).toBeTruthy()
  })
  test('set secondary color classes on primary prop', async () => {
    const { getByText, updateProps } = render(Component, {
      slots: {
        default: pTagText
      }
    })
    const secondaryClasses = getByText(pTagText).classList.toString()
    expect(secondaryClasses).toMatch('bg-secondary')
    expect(secondaryClasses).toMatch('hover:bg-secondary')
    expect(secondaryClasses).toMatch('focus:bg-secondary')
    expect(secondaryClasses).not.toMatch('bg-primary')

    await updateProps({ primary: true })
    const primaryClasses = getByText(pTagText).classList.toString()
    expect(primaryClasses).toMatch('bg-primary')
    expect(primaryClasses).toMatch('hover:bg-primary')
    expect(primaryClasses).toMatch('focus:bg-primary')
    expect(primaryClasses).not.toMatch('bg-secondary')
  })
})
