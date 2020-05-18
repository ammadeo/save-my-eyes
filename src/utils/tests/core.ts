import { render, fireEvent, RenderOptions, ComponentHarness, VueFireObject } from '@testing-library/vue'
import { VueClass } from '@vue/test-utils'
import Vue from 'vue'
import { Generate } from '@/utils/tests/dataGenerator'

const testText = Generate.string()
const testTag = `<p>${testText}</p>`

interface Temp<V extends Vue> {
  options?: RenderOptions<V>
  testName?: string
}

type select = (renderer: ComponentHarness) => HTMLElement | never


export class Base<V extends Vue>{
  protected temp: Temp<V> = {}
  constructor(protected readonly Component: VueClass<V>, protected options: RenderOptions<V> = {}){

  }
  render(additionalOptions?: RenderOptions<V>) {
    return render(this.Component, {...this.options, ...this.temp.options, ...additionalOptions})
  }

  clear(){
     this.temp = {}
  }

  setOptions(tempOptions: RenderOptions<V>) {
    this.temp.options = tempOptions
  }

  // ? tests
  testHasSlot(slotName: string = "default") {
      const { getByText } = this.render({
        slots: {
          [slotName]: testTag,
        },
      })

      const Slot = getByText(testText)
      expect(Slot).toBeVisible()
    }

    selectRoot(renderer: ComponentHarness) {
      const firstElementChild =  renderer.container.firstElementChild
      if(firstElementChild) return firstElementChild as HTMLElement
      throw new Error('no root container with first child found')
    }
  async testEmitter(select: select = this.selectRoot, eventName: keyof VueFireObject = "click", emitName: string = eventName) {
    const renderer = this.render()
    const EventSource = select(renderer)

    await fireEvent[eventName](EventSource)
    expect(renderer.emitted()[emitName]).toBeTruthy()
}
}
