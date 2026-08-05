FROM node:24.15.0-alpine3.21 AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/ ./packages/
COPY services/worker/ ./services/worker/
RUN npm install -g pnpm@11.20.0 && pnpm install --frozen-lockfile && pnpm --filter @guffsuff/worker build

FROM node:24.15.0-alpine3.21 AS runner
WORKDIR /app
USER node
ENV NODE_ENV=production
COPY --from=builder --chown=node:node /app/services/worker/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
CMD ["node", "dist/main.js"]
