FROM node:20-slim

RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY tsconfig.json *.ts ./
RUN npx tsc

EXPOSE 3050

ENV PORT=3050

CMD ["node", "dist/server.js"]
