import { render } from '@testing-library/vue'
import Component from "@/components/IndexSettings.vue";

describe("components/IndexSettings.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
