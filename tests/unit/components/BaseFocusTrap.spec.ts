import { render } from '@testing-library/vue'
import Component from "@/components/BaseFocusTrap.vue";

describe("components/BaseFocusTrap.vue", () => {
  test("has default slot", () => {
    const { getByText } = render(Component)
  });
});
