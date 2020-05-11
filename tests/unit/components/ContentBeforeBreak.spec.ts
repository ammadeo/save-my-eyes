import { render } from '@testing-library/vue'
import Component from "@/components/ContentBeforeBreak.vue";

describe("components/ContentBeforeBreak.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
