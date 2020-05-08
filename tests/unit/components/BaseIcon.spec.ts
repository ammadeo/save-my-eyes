import { render } from '@testing-library/vue'
import Component from "@/components/BaseIcon.vue";

describe("components/BaseIcon.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
