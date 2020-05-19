import { render, fireEvent } from '@testing-library/vue'
import Component from '@/components/IndexIdea.vue'
import store from '@/store'

describe('components/IndexIdea.vue', () => {
  test('render 1 card with title, content and image', () => {
    const { getByText, getByAltText } = render(Component, {
      store,
      methods: {
        random() {
          return 0
        },
      },
    })
    // @ts-ignore
    const IdeaTitle = getByText(store.state.i18n.ideas.cards[0].title['en'])
    expect(IdeaTitle).toBeVisible()

    // @ts-ignore
    const IdeaContent = getByText(store.state.i18n.ideas.cards[0].content['en'])
    expect(IdeaContent).toBeVisible()

    // @ts-ignore
    const IdeaImg = getByAltText(store.state.i18n.ideas.cards[0].img.alt['en'])
    expect(IdeaImg).toBeVisible()
  })
})
