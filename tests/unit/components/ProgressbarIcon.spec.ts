import { render } from '@testing-library/vue'
import Component from "@/components/ProgressbarIcon.vue";

describe("components/ProgressbarIcon.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
