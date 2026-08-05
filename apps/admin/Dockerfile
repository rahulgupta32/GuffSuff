FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json ./
COPY packages/ ./packages/
COPY apps/admin/ ./apps/admin/
RUN npm install -g pnpm@11.20.0 && pnpm install --frozen-lockfile && pnpm --filter @guffsuff/admin build

FROM node:24-alpine AS runner
WORKDIR /app
USER node
ENV NODE_ENV=production
COPY --from=builder --chown=node:node /app/apps/admin/.next ./.next
COPY --from=builder --chown=node:node /app/apps/admin/public ./public
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
EXPOSE 3002
CMD ["pnpm", "--filter", "@guffsuff/admin", "start"]
