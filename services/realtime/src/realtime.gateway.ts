import {
  WebSocketGateway,
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket
} from "@nestjs/websockets";
import { Server, Socket } from "socket.io";
import { RealtimeEventEnvelopeSchema } from "@guffsuff/contracts";

@WebSocketGateway({ cors: { origin: "*" } })
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  handleConnection(client: Socket) {
    const token = client.handshake.auth?.token;
    const deviceId = client.handshake.auth?.deviceId;
    const userId = client.handshake.auth?.userId;

    if (!token || !deviceId || !userId) {
      console.warn(
        `[REALTIME-SECURITY] Rejected unauthenticated connection attempt ID: ${client.id}`
      );
      client.disconnect(true);
      return;
    }

    client.join(`user_${userId}`);
    client.join(`device_${deviceId}`);
    console.log(`[REALTIME] Device connected: ${deviceId} for User: ${userId}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`[REALTIME] Client disconnected ID: ${client.id}`);
  }

  sendIdentityNotification(
    userId: string,
    eventType: "device_revoked" | "session_revoked" | "security_alert",
    payload: Record<string, unknown>
  ) {
    if (this.server) {
      this.server.to(`user_${userId}`).emit("identity_event", {
        eventType,
        payload,
        timestamp: Date.now()
      });
    }
  }

  sendDeliveryEvent(recipientDeviceId: string, payload: Record<string, unknown>) {
    if (this.server) {
      this.server.to(`device_${recipientDeviceId}`).emit("server.message.delivery", {
        eventType: "server.message.delivery",
        payload,
        timestamp: Date.now()
      });
    }
  }

  sendAcceptedEvent(senderDeviceId: string, payload: Record<string, unknown>) {
    if (this.server) {
      this.server.to(`device_${senderDeviceId}`).emit("server.message.accepted", {
        eventType: "server.message.accepted",
        payload,
        timestamp: Date.now()
      });
    }
  }

  @SubscribeMessage("client.message.submit")
  handleClientMessageSubmit(@ConnectedSocket() client: Socket, @MessageBody() data: unknown) {
    const parsed = RealtimeEventEnvelopeSchema.safeParse(data);
    if (!parsed.success) {
      client.emit("server.protocol.error", {
        errorCode: "INVALID_EVENT_FORMAT",
        message: "Schema validation failed"
      });
      return;
    }
    client.emit("server.message.accepted", {
      eventId: parsed.data.eventId,
      correlationId: parsed.data.correlationId,
      status: "accepted",
      timestamp: Date.now()
    });
  }

  @SubscribeMessage("client.message.delivered")
  handleClientMessageDelivered(@ConnectedSocket() client: Socket, @MessageBody() data: unknown) {
    const parsed = RealtimeEventEnvelopeSchema.safeParse(data);
    if (!parsed.success) {
      client.emit("server.protocol.error", {
        errorCode: "INVALID_EVENT_FORMAT",
        message: "Schema validation failed"
      });
      return;
    }
    client.emit("server.message.status", {
      eventId: parsed.data.eventId,
      status: "delivered",
      timestamp: Date.now()
    });
  }

  @SubscribeMessage("client.message.read")
  handleClientMessageRead(@ConnectedSocket() client: Socket, @MessageBody() data: unknown) {
    const parsed = RealtimeEventEnvelopeSchema.safeParse(data);
    if (!parsed.success) {
      client.emit("server.protocol.error", {
        errorCode: "INVALID_EVENT_FORMAT",
        message: "Schema validation failed"
      });
      return;
    }
    client.emit("server.message.status", {
      eventId: parsed.data.eventId,
      status: "read",
      timestamp: Date.now()
    });
  }
}
