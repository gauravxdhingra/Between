import { FastifyInstance } from 'fastify';
import prisma from '../lib/prisma';
import { authenticate } from '../middleware/auth';

export default async function inviteRoutes(app: FastifyInstance) {
  // GET /invites/:token — resolve invite (no auth required, used before sign-in)
  app.get('/:token', async (request, reply) => {
    const { token } = request.params as { token: string };

    const invite = await prisma.inviteToken.findUnique({
      where: { token },
      include: {
        group: {
          select: {
            id: true,
            name: true,
            emoji: true,
            _count: { select: { members: true } },
          },
        },
      },
    });

    if (!invite) return reply.status(404).send({ error: 'Invite not found or expired' });

    if (invite.expiresAt && invite.expiresAt < new Date()) {
      return reply.status(410).send({ error: 'Invite link has expired' });
    }

    return { group: invite.group };
  });

  // POST /invites/:token/join — join the group
  app.post('/:token/join', { preHandler: authenticate }, async (request, reply) => {
    const { token } = request.params as { token: string };

    const invite = await prisma.inviteToken.findUnique({
      where: { token },
    });

    if (!invite) return reply.status(404).send({ error: 'Invite not found or expired' });

    if (invite.expiresAt && invite.expiresAt < new Date()) {
      return reply.status(410).send({ error: 'Invite link has expired' });
    }

    // Idempotent — silently succeed if already a member
    await prisma.groupMember.upsert({
      where: {
        groupId_userId: { groupId: invite.groupId, userId: request.userId },
      },
      create: { groupId: invite.groupId, userId: request.userId },
      update: {},
    });

    const group = await prisma.group.findUnique({
      where: { id: invite.groupId },
      include: {
        members: { include: { user: { select: { id: true, name: true } } } },
        inviteToken: { select: { token: true } },
      },
    });

    return reply.status(200).send(group);
  });
}
