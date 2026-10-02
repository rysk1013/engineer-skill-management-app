FROM node:24-bookworm-slim AS base

WORKDIR /app

RUN corepack enable


FROM base AS dependencies

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --frozen-lockfile


FROM dependencies AS development

COPY . .

CMD ["pnpm", "run", "dev", "--hostname", "0.0.0.0"]


FROM dependencies AS builder

COPY . .

RUN pnpm run build


FROM node:24-bookworm-slim AS production

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

CMD ["node", "server.js"]
