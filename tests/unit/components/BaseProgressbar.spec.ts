import { render } from '@testing-library/vue'
import Component from "@/components/BaseProgressbar.vue";
import { Base } from '@/utils/tests/core'


const generateProps = (value: number) => ({
  value: value,
  max: 100,
  min: 0,
})

const base = new Base(Component, {props: generateProps(30)})

describe("components/BaseProgressbar.vue",  () => {
  test("has default slot", ()=> base.testHasSlot())
  test("translateX progress based on props", async () => {
    const renderer = base.render()
    const root = base.selectRoot(renderer)
    const progress = root.firstElementChild
    expect(progress).toHaveStyle('transform: translateX(-70%)')
    await renderer.updateProps(generateProps(0))
    expect(progress).toHaveStyle('transform: translateX(-100%)')
    await renderer.updateProps(generateProps(100))
    expect(progress).toHaveStyle('transform: translateX(-0%)')
  });
  test("set aria attributes based on props", async () => {
    const {getByRole, updateProps} = base.render()
    const progressbar = getByRole("progressbar")

    expect(progressbar).toHaveAttribute("aria-valuemax", "100")
    expect(progressbar).toHaveAttribute("aria-valuemin", "0")
    expect(progressbar).toHaveAttribute("aria-valuenow", "30")
    await updateProps(generateProps(0))
        expect(progressbar).toHaveAttribute("aria-valuenow", "0")

    await updateProps(generateProps(100))
    expect(progressbar).toHaveAttribute("aria-valuenow", "100")

  });
});
