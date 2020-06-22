import { fireEvent } from '@testing-library/vue'
import Component from '@/components/ButtonToggle.vue'
import { Base } from '@/utils/tests/core'
const iconOnContent = 'iconOn'
const iconOffContent = 'iconOff'
const base = new Base(Component, {
  props: {
    on: true,
  },
  slots: {
    iconOn: `<p>${iconOnContent}</p>`,
    iconOff: `<p>${iconOffContent}</p>`,
  },
})

describe('components/ButtonToggle.vue', () => {
  test('emit toggle on click', () =>
    base.testEmitter(
      (renderer) => base.selectRoot(renderer),
      'click',
      'toggle'
    ))

  test('toggle has working on and off state', async () => {
    const { getAllByText, updateProps } = base.render()
    const Button = base.selectRoot()
    const Thumb = Button.lastElementChild
    let iconOns = getAllByText(iconOnContent)
    let iconOffs = getAllByText(iconOffContent)

    expect(iconOns).toHaveLength(2)
    expect(iconOffs).toHaveLength(1)
    expect(Thumb).not.toHaveClass('translate-x-8')
    await updateProps({ on: false })

    iconOns = getAllByText(iconOnContent)
    iconOffs = getAllByText(iconOffContent)

    expect(iconOns).toHaveLength(1)
    expect(iconOffs).toHaveLength(2)
    expect(Thumb).toHaveClass('translate-x-8')
  })
})
