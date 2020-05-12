import { render } from '@testing-library/vue'
import Component from "@/components/IndexStopProtection.vue";

describe("components/IndexStopProtection.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
