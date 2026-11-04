import { fireEvent } from '@testing-library/vue'
import Component from '@/components/ButtonToggleLabeled.vue'
import { Base } from '@/utils/tests/core'
const iconOnContent = 'iconOn',
  iconOffContent = 'iconOff',
  stateOn = 'stateOn',
  stateOff = 'stateOff'
const base = new Base(Component, {
  props: {
    on: true,
    stateOn,
    stateOff,
  },
  slots: {
    iconOn: `<p>${iconOnContent}</p>`,
    iconOff: `<p>${iconOffContent}</p>`,
  },
})

describe('components/ButtonToggleLabeled.vue', () => {
  test('toggle state', async () => {
    const { getByText, updateProps } = base.render()
    let State = getByText(stateOn)
    expect(State).toBeVisible()

    await updateProps({ on: false })

    State = getByText(stateOff)
    expect(State).toBeVisible()
  })
})
