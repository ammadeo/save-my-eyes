import { render, fireEvent, RenderOptions, ComponentHarness } from '@testing-library/vue'
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


export class BasicTest<V extends Vue>{
  protected temp: Temp<V> = {}
  constructor(protected readonly Component: VueClass<V>, protected options: RenderOptions<V> = {}){

  }
  protected render(additionalOptions?: RenderOptions<V>) {
    return render(this.Component, {...this.options, ...this.temp.options, ...additionalOptions})
  }


  protected isEmptyTemp(){
    return Object.entries(this.temp).length === 0
  }

  protected clear(){
     this.temp = {}
  }

  run(testName: string) {
    if(!this.isEmptyTemp()) throw new Error(`temporary variables weren't cleared in last test (${this.temp.testName}) call .clear on this test`)
    this.temp.testName = testName
    return this
  }
  setOptions(tempOptions: RenderOptions<V>) {
    this.temp.options = tempOptions
    return this
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

    protected RootSelector(renderer: ComponentHarness) {
      const firstChild =  renderer.container.firstChild
      if(firstChild) return firstChild as HTMLElement
      throw new Error('no root container with first child found')
    }
  async testClickEmit(select: select = this.RootSelector) {
      const renderer = this.render()
      const Clicker = select(renderer)

      await fireEvent.click(Clicker)
      expect(renderer.emitted().click).toBeTruthy()
  }
}
