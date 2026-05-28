import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import prisma from '../lib/prisma';
import { authenticate } from '../middleware/auth';

const splitEntrySchema = z.object({
  userId: z.string(),
  amount: z.number().positive(),
});

const createSchema = z.object({
  title: z.string().min(1).max(60),
  amount: z.number().positive().max(999999),
  paidById: z.string(),
  splitType: z.enum(['equal', 'custom']).default('equal'),
  note: z.string().max(200).optional(),
  splits: z.array(splitEntrySchema).min(1),
});

export default async function expenseRoutes(app: FastifyInstance) {
  // GET /groups/:groupId/expenses
  app.get('/:groupId/expenses', { preHandler: authenticate }, async (request, reply) => {
    const { groupId } = request.params as { groupId: string };

    const member = await prisma.groupMember.findUnique({
      where: { groupId_userId: { groupId, userId: request.userId } },
    });
    if (!member) return reply.status(403).send({ error: 'Not a member' });

    const expenses = await prisma.expense.findMany({
      where: { groupId, deletedAt: null },
      include: {
        paidBy: { select: { id: true, name: true } },
        splits: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return expenses;
  });

  // POST /groups/:groupId/expenses
  app.post('/:groupId/expenses', { preHandler: authenticate }, async (request, reply) => {
    const { groupId } = request.params as { groupId: string };
    const body = createSchema.safeParse(request.body);
    if (!body.success) return reply.status(400).send({ error: body.error.flatten() });

    const member = await prisma.groupMember.findUnique({
      where: { groupId_userId: { groupId, userId: request.userId } },
    });
    if (!member) return reply.status(403).send({ error: 'Not a member' });

    // Validate split total matches amount
    const splitTotal = body.data.splits.reduce((s, e) => s + e.amount, 0);
    if (Math.abs(splitTotal - body.data.amount) > 0.01) {
      return reply.status(400).send({ error: 'Split amounts must sum to the total' });
    }

    const expense = await prisma.expense.create({
      data: {
        groupId,
        title: body.data.title,
        amount: body.data.amount,
        paidById: body.data.paidById,
        splitType: body.data.splitType,
        note: body.data.note,
        createdById: request.userId,
        splits: {
          create: body.data.splits.map((s) => ({
            userId: s.userId,
            amount: s.amount,
          })),
        },
      },
      include: {
        paidBy: { select: { id: true, name: true } },
        splits: true,
      },
    });

    // Touch group updatedAt
    await prisma.group.update({
      where: { id: groupId },
      data: { updatedAt: new Date() },
    });

    return reply.status(201).send(expense);
  });

  // DELETE /groups/:groupId/expenses/:expenseId
  app.delete(
    '/:groupId/expenses/:expenseId',
    { preHandler: authenticate },
    async (request, reply) => {
      const { groupId, expenseId } = request.params as {
        groupId: string;
        expenseId: string;
      };

      const expense = await prisma.expense.findFirst({
        where: { id: expenseId, groupId, deletedAt: null },
      });
      if (!expense) return reply.status(404).send({ error: 'Expense not found' });
      if (expense.createdById !== request.userId)
        return reply.status(403).send({ error: 'Only the creator can delete this expense' });

      await prisma.expense.update({
        where: { id: expenseId },
        data: { deletedAt: new Date() },
      });
      return reply.status(204).send();
    },
  );
}
