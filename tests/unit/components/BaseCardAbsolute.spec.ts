import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/CardFocusable.vue'
import { Generate } from '@/utils/tests/dataGenerator'

const pTAgTExt = Generate.string()
const pTag = `<p>${pTAgTExt}</p>`

describe('components/CardFocusable.vue', () => {
  test('has content slot', async () => {
    const { getByText } = render(Component, {
      slots: {
        default: pTag,
      },
    })

    const Tested = getByText(pTAgTExt)

    expect(Tested).toBeVisible()
  })
  test('on hover emit mouseenter and mouseleave', async () => {
    const { getByText, emitted } = render(Component, {
      slots: {
        default: pTAgTExt,
      },
    })
    const Tested = getByText(pTAgTExt)
    await fireEvent.mouseOver(Tested)
    expect(emitted().focusin).toBeTruthy()
    await fireEvent.mouseLeave(Tested)
    expect(emitted().focusout).toBeTruthy()
  })
})
