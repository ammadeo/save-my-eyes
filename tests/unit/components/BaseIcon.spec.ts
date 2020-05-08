import { render } from '@testing-library/vue'
import Component from "@/components/BaseIcon.vue";

describe("components/BaseIcon.vue", () => {
  test("set icon based on prop", async () => {
    const { getByAltText, updateProps } = render(Component, {
      props:{
        icon: 'close'
      }
    })
    const icons = ['close', 'pause', 'settings', 'skip', 'start', 'stop']
    for (const icon of icons) {
      await updateProps({icon})
      expect(getByAltText(`${icon} icon`)).toBeVisible()
    }

  });
  test("set icon colour by dark prop", async () => {
    const { getByAltText, updateProps } = render(Component, {
      props:{
        icon: 'close',
      }
    })

    expect(getByAltText('close icon')).toHaveClass("fill-current","text-primary-100")

    await updateProps({icon: 'close', dark: true})
    expect(getByAltText('close icon')).toHaveClass("fill-current","text-primary-800")
  });
});
