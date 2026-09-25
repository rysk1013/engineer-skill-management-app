import { getHealth } from "@/lib/api";

export async function GET() {
  const health = await getHealth();

  return Response.json(health);
}
