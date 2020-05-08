import { render } from '@testing-library/vue'
import Component from "@/components/BaseInputRange.vue";

describe("components/BaseInputRange.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
