import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import profileRoutes from '../src/routes/profiles';
import groupRoutes from '../src/routes/groups';
import expenseRoutes from '../src/routes/expenses';
import settlementRoutes from '../src/routes/settlements';
import inviteRoutes from '../src/routes/invites';

const app = Fastify({ logger: false });

app.register(cors, { origin: true });
app.register(profileRoutes, { prefix: '/profiles' });
app.register(groupRoutes, { prefix: '/groups' });
app.register(expenseRoutes, { prefix: '/groups' });
app.register(settlementRoutes, { prefix: '/groups' });
app.register(inviteRoutes, { prefix: '/invites' });
app.get('/health', async () => ({ status: 'ok' }));

export default async function handler(req: any, res: any) {
  await app.ready();
  app.server.emit('request', req, res);
}
