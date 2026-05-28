import { FastifyRequest, FastifyReply } from 'fastify';
import { supabase } from '../lib/supabase';
import prisma from '../lib/prisma';

export async function authenticate(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  const authHeader = request.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return reply.status(401).send({ error: 'Missing authorization header' });
  }

  const token = authHeader.slice(7);
  const { data, error } = await supabase.auth.getUser(token);

  if (error || !data.user) {
    return reply.status(401).send({ error: 'Invalid or expired token' });
  }

  request.userId = data.user.id;

  // Ensure a Profile row exists so FK constraints never fail downstream
  const phone = data.user.phone ?? undefined;
  const name = phone ?? data.user.email ?? request.userId;
  await prisma.profile.upsert({
    where: { id: request.userId },
    create: { id: request.userId, name, phone },
    update: {},
  });
}

// Extend FastifyRequest to carry userId
declare module 'fastify' {
  interface FastifyRequest {
    userId: string;
  }
}
