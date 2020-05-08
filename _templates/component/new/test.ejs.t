---
to: tests/unit/components/<%= h.changeCase.pascal(name) %>.test.ts
---
import { render } from '@testing-library/vue'
import Component from "@/components/<%= h.changeCase.pascal(name) %>.vue";

describe("components/<%= h.changeCase.pascal(name) %>.vue", () => {
  test("", () => {
    const { getByText } = render(Component)
  });
});
