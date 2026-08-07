import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
  Inject
} from "@nestjs/common";
import { DeviceService } from "./device.service.js";
import { JwtAuthGuard } from "./jwt-auth.guard.js";

@Controller("api/v1/devices")
@UseGuards(JwtAuthGuard)
export class DevicesController {
  constructor(@Inject("DEVICE_SERVICE") private readonly deviceService: DeviceService) {}

  @Get()
  async listDevices(@Req() req: any) {
    return this.deviceService.listDevices(req.user.userId, req.user.deviceId);
  }

  @Patch(":id")
  async renameDevice(
    @Req() req: any,
    @Param("id") deviceId: string,
    @Body("deviceName") deviceName: string
  ) {
    return this.deviceService.renameDevice(req.user.userId, deviceId, deviceName);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.OK)
  async revokeDevice(@Req() req: any, @Param("id") deviceId: string) {
    return this.deviceService.revokeDevice(req.user.userId, deviceId);
  }
}
