import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/HelpCards.vue'
import { i18nStore } from '../../utils/testsVuexI18n'
describe('components/HelpCards.vue', () => {
  test('on mouse hover events emit changeAutoFinishLock', async () => {
    const { getAllByTestId, emitted } = render(Component, { store: i18nStore })
    const Tested = getAllByTestId('help-card')[0]
    //? BaseCard has smart sizing parent
    const actualCard = Tested.firstElementChild
    await fireEvent.mouseOver(actualCard)
    expect(emitted().changeAutoFinishLock[0]).toEqual([true])
    await fireEvent.mouseLeave(actualCard)
    expect(emitted().changeAutoFinishLock[1]).toEqual([false])
  })
  test('render 3 cards with title and content', () => {
    const { getAllByTestId } = render(Component, { store: i18nStore })
    const TestedAll = getAllByTestId('help-card')
    expect(TestedAll).toHaveLength(3)
  })
})
