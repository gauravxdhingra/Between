import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import profileRoutes from './routes/profiles';
import groupRoutes from './routes/groups';
import expenseRoutes from './routes/expenses';
import settlementRoutes from './routes/settlements';
import inviteRoutes from './routes/invites';

async function bootstrap() {
  const app = Fastify({
    logger: {
      transport:
        process.env.NODE_ENV === 'development'
          ? { target: 'pino-pretty' }
          : undefined,
    },
  });

  await app.register(cors, {
    origin: process.env.ALLOWED_ORIGINS?.split(',') ?? true,
  });

  await app.register(profileRoutes, { prefix: '/profiles' });
  await app.register(groupRoutes, { prefix: '/groups' });
  await app.register(expenseRoutes, { prefix: '/groups' });
  await app.register(settlementRoutes, { prefix: '/groups' });
  await app.register(inviteRoutes, { prefix: '/invites' });

  app.get('/health', async () => ({ status: 'ok' }));

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.HOST ?? '0.0.0.0';

  try {
    await app.listen({ port, host });
    console.log(`Server running on http://${host}:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

bootstrap();
