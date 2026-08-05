import { WebSocketGateway, OnGatewayConnection, OnGatewayDisconnect } from "@nestjs/websockets";
import { Socket } from "socket.io";

@WebSocketGateway({ cors: { origin: "*" } })
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
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
}
