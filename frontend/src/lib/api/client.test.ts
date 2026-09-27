import { describe, expect, it } from "vitest";

import { getHealth } from "./client";

describe("getHealth", () => {
  it("returns the health response from the backend API", async () => {
    const response = await getHealth();

    expect(response).toEqual({
      status: "ok",
    });
  });
});
