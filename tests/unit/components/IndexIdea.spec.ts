import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/IndexIdea.vue'
import store from '@/store'
describe('components/IndexIdea.vue', () => {
  test('on mouse hover events emit changeAutoFinishLock', async () => {
    const { getAllByTestId, emitted } = render(Component, { store })
    const Tested = getAllByTestId('help-card')[0]
    //? CardFocusable has smart sizing parent
    const actualCard = Tested.firstElementChild

    if (!actualCard) throw Error('no card found')

    await fireEvent.mouseOver(actualCard)
    expect(emitted().changeAutoFinishLock[0]).toEqual([true])
    await fireEvent.mouseLeave(actualCard)
    expect(emitted().changeAutoFinishLock[1]).toEqual([false])
  })
  test('render 3 cards with title and content', () => {
    const { getAllByTestId } = render(Component, { store })
    const TestedAll = getAllByTestId('help-card')
    expect(TestedAll).toHaveLength(3)
  })
})
