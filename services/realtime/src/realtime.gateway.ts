import { WebSocketGateway, OnGatewayConnection, OnGatewayDisconnect, WebSocketServer } from "@nestjs/websockets";
import { Server, Socket } from "socket.io";

@WebSocketGateway({ cors: { origin: "*" } })
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  handleConnection(client: Socket) {
    const token = client.handshake.auth?.token;
    if (!token) {
      console.warn(
        `[REALTIME-SECURITY] Rejected unauthenticated connection attempt ID: ${client.id}`
      );
      client.disconnect(true);
      return;
    }
    console.log(`[REALTIME] Client connected ID: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`[REALTIME] Client disconnected ID: ${client.id}`);
  }

  /**
   * Realtime revocation events are notifications ONLY.
   * Server-side session and API token authorization checks remain authoritative.
   */
  sendIdentityNotification(userId: string, eventType: "device_revoked" | "session_revoked" | "security_alert", payload: Record<string, unknown>) {
    if (this.server) {
      this.server.to(`user_${userId}`).emit("identity_event", {
        eventType,
        payload,
        timestamp: Date.now()
      });
    }
  }
}
