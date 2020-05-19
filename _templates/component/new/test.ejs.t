---
to: tests/unit/components/<%= h.changeCase.pascal(name) %>.spec.ts
---
import { render } from '@testing-library/vue'
import Component from "@/components/<%= h.changeCase.pascal(name) %>.vue";

describe("components/<%= h.changeCase.pascal(name) %>.vue", () => {
  test.todo("implement tests!")
  test("", () => {
    const { getByText } = render(Component)
  });
});
