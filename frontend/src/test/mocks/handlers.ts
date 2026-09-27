import { http, HttpResponse } from "msw";

const backendApiUrl = process.env.BACKEND_API_URL;

if (!backendApiUrl) {
  throw new Error("BACKEND_API_URL is not configured");
}

export const handlers = [
  http.get(`${backendApiUrl}/health`, () => {
    return HttpResponse.json({
      status: "ok",
    });
  }),
];
