import { describe, expect, it } from "vitest";

import { formatDisplayName } from "./format-display-name";

describe("formatDisplayName", () => {
  it("joins the family name and given name with a space", () => {
    expect(formatDisplayName("Yamada", "Taro")).toBe("Yamada Taro");
  });
});
