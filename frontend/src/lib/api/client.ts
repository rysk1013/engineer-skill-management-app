import "server-only";

import type { paths } from "./generated/schema";

type HealthResponse =
  paths["/health"]["get"]["responses"][200]["content"]["application/json"];

function getBackendApiUrl(): string {
  const backendApiUrl = process.env.BACKEND_API_URL;

  if (!backendApiUrl) {
    throw new Error("BACKEND_API_URL is not configured");
  }

  return backendApiUrl;
}

export async function getHealth(): Promise<HealthResponse> {
  const backendApiUrl = getBackendApiUrl();

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
