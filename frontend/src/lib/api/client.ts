import "server-only";

import type { paths } from "./generated/schema";

const backendApiUrl = process.env.BACKEND_API_URL;

if (!backendApiUrl) {
  throw new Error("BACKEND_API_URL is not configured");
}

type HealthResponse = paths["/health"]["get"]["responses"][200]["content"]["application/json"];

export async function getHealth(): Promise<HealthResponse> {
  const response = await fetch(`${backendApiUrl}/health`, {
    method: "GET",
    headers: {
      Accept: "application/json",
    },
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Backend API request failed: ${response.status}`);
  }

  return (await response.json()) as HealthResponse;
}
