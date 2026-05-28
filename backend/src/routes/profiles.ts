import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { authenticate } from '../middleware/auth';

const upsertSchema = z.object({
  name: z.string().min(1).max(80),
  phone: z.string().optional(),
  avatarUrl: z.string().url().optional(),
});

export default async function profileRoutes(app: FastifyInstance) {
  // GET /profiles/me
  app.get('/me', { preHandler: authenticate }, async (request, reply) => {
    const profile = await prisma.profile.findUnique({
      where: { id: request.userId },
    });
    if (!profile) return reply.status(404).send({ error: 'Profile not found' });
    return profile;
  });

  // PUT /profiles/me
  app.put('/me', { preHandler: authenticate }, async (request, reply) => {
    const body = upsertSchema.safeParse(request.body);
    if (!body.success) return reply.status(400).send({ error: body.error.flatten() });

    const profile = await prisma.profile.upsert({
      where: { id: request.userId },
      create: { id: request.userId, ...body.data },
      update: body.data,
    });
    return profile;
  });
}
