import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { authenticate } from '../middleware/auth';

const createSchema = z.object({
  fromId: z.string(),
  toId: z.string(),
  amount: z.number().positive(),
  note: z.string().max(200).optional(),
});

export default async function settlementRoutes(app: FastifyInstance) {
  // GET /groups/:groupId/settlements
  app.get('/:groupId/settlements', { preHandler: authenticate }, async (request, reply) => {
    const { groupId } = request.params as { groupId: string };

    const member = await prisma.groupMember.findUnique({
      where: { groupId_userId: { groupId, userId: request.userId } },
    });
    if (!member) return reply.status(403).send({ error: 'Not a member' });

    const settlements = await prisma.settlement.findMany({
      where: { groupId },
      include: {
        from: { select: { id: true, name: true } },
        to: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return settlements;
  });

  // POST /groups/:groupId/settlements
  app.post('/:groupId/settlements', { preHandler: authenticate }, async (request, reply) => {
    const { groupId } = request.params as { groupId: string };
    const body = createSchema.safeParse(request.body);
    if (!body.success) return reply.status(400).send({ error: body.error.flatten() });

    const member = await prisma.groupMember.findUnique({
      where: { groupId_userId: { groupId, userId: request.userId } },
    });
    if (!member) return reply.status(403).send({ error: 'Not a member' });

    const settlement = await prisma.settlement.create({
      data: { groupId, ...body.data },
      include: {
        from: { select: { id: true, name: true } },
        to: { select: { id: true, name: true } },
      },
    });
    return reply.status(201).send(settlement);
  });
}
