FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json turbo.json ./
COPY packages/ ./packages/
COPY services/api/ ./services/api/
RUN npm install -g pnpm@11.20.0 && pnpm install --frozen-lockfile && pnpm build

FROM node:24-alpine AS runner
WORKDIR /app
USER node
ENV NODE_ENV=production
COPY --from=builder --chown=node:node /app/services/api/dist ./dist
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/main.js"]
