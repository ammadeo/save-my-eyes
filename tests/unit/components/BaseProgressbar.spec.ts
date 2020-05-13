import { render } from '@testing-library/vue'
import Component from "@/components/BaseProgressbar.vue";

describe("components/BaseProgressbar.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
