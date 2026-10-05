import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException
} from "@nestjs/common";
import { createDatabasePool } from "@guffsuff/database";
import { generateUUIDv7 } from "@guffsuff/id-generation";

@Injectable()
export class ConversationService {
  private pool = createDatabasePool();

  async getOrCreateDirectConversation(userId: string, recipientUserId: string) {
    if (userId === recipientUserId) {
      throw new BadRequestException("Cannot create a direct conversation with yourself");
    }

    // Verify recipient user exists and is active
    const recipientRes = await this.pool.query(
      "SELECT id, account_state FROM users WHERE id = $1",
      [recipientUserId]
    );
    if (recipientRes.rows.length === 0 || recipientRes.rows[0].account_state === "deleted") {
      throw new NotFoundException("Recipient user not found");
    }

    const p1 = userId < recipientUserId ? userId : recipientUserId;
    const p2 = userId < recipientUserId ? recipientUserId : userId;

    const convId = generateUUIDv7();
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");

      const insertConv = await client.query(
        `INSERT INTO direct_conversations (id, participant1_user_id, participant2_user_id)
         VALUES ($1, $2, $3) ON CONFLICT DO NOTHING RETURNING id, participant1_user_id, participant2_user_id, created_at`,
        [convId, p1, p2]
      );

      const conversation =
        insertConv.rows[0] ??
        (
          await client.query(
            "SELECT id, participant1_user_id, participant2_user_id, created_at FROM direct_conversations WHERE LEAST(participant1_user_id, participant2_user_id) = $1 AND GREATEST(participant1_user_id, participant2_user_id) = $2",
            [p1, p2]
          )
        ).rows[0];
      if (!conversation)
        throw new Error("Conversation creation returned no persisted conversation");

      const mem1Id = generateUUIDv7();
      const mem2Id = generateUUIDv7();
      await client.query(
        `INSERT INTO conversation_members (id, conversation_id, user_id) VALUES ($1, $2, $3), ($4, $2, $5) ON CONFLICT (conversation_id, user_id) DO NOTHING`,
        [mem1Id, conversation.id, p1, mem2Id, p2]
      );

      await client.query("COMMIT");
      return conversation;
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  }

  async listConversations(userId: string) {
    const res = await this.pool.query(
      `SELECT c.id, c.participant1_user_id, c.participant2_user_id, c.created_at, c.updated_at
       FROM direct_conversations c
       JOIN conversation_members m ON c.id = m.conversation_id
       WHERE m.user_id = $1
       ORDER BY c.updated_at DESC`,
      [userId]
    );
    return res.rows;
  }

  async getConversationById(userId: string, conversationId: string) {
    const res = await this.pool.query(
      `SELECT c.id, c.participant1_user_id, c.participant2_user_id, c.created_at, c.updated_at
       FROM direct_conversations c
       JOIN conversation_members m ON c.id = m.conversation_id
       WHERE c.id = $1 AND m.user_id = $2`,
      [conversationId, userId]
    );

    if (res.rows.length === 0) {
      throw new ForbiddenException("Conversation not found or access denied");
    }

    return res.rows[0];
  }
}
