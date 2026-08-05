import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module.js";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: (
      process.env.CORS_ALLOWED_ORIGINS || "http://localhost:3000,http://localhost:3002"
    ).split(","),
    credentials: true
  });

  const config = new DocumentBuilder()
    .setTitle("GuffSuff Core API Gateway")
    .setDescription("GuffSuff REST API Service Specifications")
    .setVersion("0.1.0-dev")
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup("api/docs", app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`[API-SERVICE] GuffSuff API service listening on port ${port}`);
}

bootstrap();
