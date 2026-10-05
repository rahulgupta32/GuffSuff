import { test } from "node:test";
import assert from "node:assert/strict";
import { ConversationService } from "../conversation.service.js";

for (const conflict of [false, true]) {
  test(`conversation creation commits memberships for ${conflict ? "a competing existing" : "a new"} conversation`, async () => {
    const calls: { sql: string; values: unknown[] }[] = [];
    const conversation = { id: "persisted-conversation" };
    let released = false;
    const client = {
      query: async (sql: string, values: unknown[] = []) => {
        calls.push({ sql, values });
        if (sql.includes("INSERT INTO direct_conversations"))
          return { rows: conflict ? [] : [conversation] };
        if (sql.includes("SELECT id, participant1_user_id")) return { rows: [conversation] };
        return { rows: [] };
      },
      release: () => {
        released = true;
      }
    };
    const service = new ConversationService();
    Object.assign(service, {
      pool: {
        query: async () => ({ rows: [{ account_state: "active" }] }),
        connect: async () => client
      }
    });
    const result = await service.getOrCreateDirectConversation("b", "a");
    assert.equal(result.id, conversation.id);
    assert.match(
      calls.find((c) => c.sql.includes("INSERT INTO direct_conversations"))!.sql,
      /ON CONFLICT DO NOTHING/
    );
    const membership = calls.find((c) => c.sql.includes("INSERT INTO conversation_members"))!;
    assert.equal(membership.values[1], conversation.id);
    assert.match(membership.sql, /ON CONFLICT \(conversation_id, user_id\) DO NOTHING/);
    assert.equal(calls.at(-1)!.sql, "COMMIT");
    assert.equal(released, true);
  });
}
