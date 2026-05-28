import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { authenticate } from '../middleware/auth';

const createSchema = z.object({
  name: z.string().min(1).max(80),
  emoji: z.string().default('🏠'),
});

const updateSchema = z.object({
  name: z.string().min(1).max(80).optional(),
  emoji: z.string().optional(),
});

export default async function groupRoutes(app: FastifyInstance) {
  // GET /groups — all groups the user belongs to
  app.get('/', { preHandler: authenticate }, async (request) => {
    const groups = await prisma.group.findMany({
      where: { members: { some: { userId: request.userId } } },
      include: {
        members: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        inviteToken: { select: { token: true } },
        _count: { select: { expenses: { where: { deletedAt: null } } } },
      },
      orderBy: { updatedAt: 'desc' },
    });
    return groups;
  });

  // POST /groups
  app.post('/', { preHandler: authenticate }, async (request, reply) => {
    const body = createSchema.safeParse(request.body);
    if (!body.success) return reply.status(400).send({ error: body.error.flatten() });

    const group = await prisma.group.create({
      data: {
        name: body.data.name,
        emoji: body.data.emoji,
        createdBy: request.userId,
        members: { create: { userId: request.userId } },
        inviteToken: { create: {} },
      },
      include: {
        members: { include: { user: { select: { id: true, name: true } } } },
        inviteToken: { select: { token: true } },
      },
    });
    return reply.status(201).send(group);
  });

  // GET /groups/:id
  app.get('/:id', { preHandler: authenticate }, async (request, reply) => {
    const { id } = request.params as { id: string };

    const group = await prisma.group.findFirst({
      where: { id, members: { some: { userId: request.userId } } },
      include: {
        members: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        inviteToken: { select: { token: true } },
      },
    });
    if (!group) return reply.status(404).send({ error: 'Group not found' });
    return group;
  });

  // PATCH /groups/:id
  app.patch('/:id', { preHandler: authenticate }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = updateSchema.safeParse(request.body);
    if (!body.success) return reply.status(400).send({ error: body.error.flatten() });

    const member = await prisma.groupMember.findUnique({
      where: { groupId_userId: { groupId: id, userId: request.userId } },
    });
    if (!member) return reply.status(403).send({ error: 'Not a member' });

    const group = await prisma.group.update({ where: { id }, data: body.data });
    return group;
  });

  // DELETE /groups/:id
  app.delete('/:id', { preHandler: authenticate }, async (request, reply) => {
    const { id } = request.params as { id: string };

    const group = await prisma.group.findUnique({ where: { id } });
    if (!group) return reply.status(404).send({ error: 'Group not found' });
    if (group.createdBy !== request.userId)
      return reply.status(403).send({ error: 'Only the creator can delete a group' });

    await prisma.group.delete({ where: { id } });
    return reply.status(204).send();
  });
}
