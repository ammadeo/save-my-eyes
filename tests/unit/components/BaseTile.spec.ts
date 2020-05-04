import { render } from '@testing-library/vue'
import Component from '@/components/BaseTile.vue'
import { Generate } from '@/utils/testsDataGenerator'

const pTAgText = Generate.string()
const pTag = `<p>${pTAgText}</p>`

describe('components/BaseTile.vue', () => {
  test('has content slot', () => {
    const { getByText } = render(Component, {
      slots: {
        default: pTag,
      },
    })

    const progressbar = getByText(pTAgText)

    expect(progressbar).toBeVisible()
  })

  test('can be as a button', () => {
    const { getByText } = render(Component, {
      slots: {
        default: pTAgText,
      },
      props: {
        color: 'secondary-300',
        as: 'button',
      },
    })
    expect(getByText(pTAgText).tagName).toMatch('BUTTON')
  })
})
