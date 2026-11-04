---
to: tests/unit/components/<%= h.changeCase.pascal(name) %>.spec.ts
---
import { fireEvent } from '@testing-library/vue'
import { Base } from '@/utils/tests/core'
import Component from "@/components/<%= h.changeCase.pascal(name) %>.vue";
const base = new Base(Component)

describe("components/<%= h.changeCase.pascal(name) %>.vue", () => {
  test.todo("implement tests!")
  test("", async () => {
    const { getByText } = base.render()
  });
});
