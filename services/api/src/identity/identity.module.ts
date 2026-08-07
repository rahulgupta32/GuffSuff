import { Module } from "@nestjs/common";
import { createDatabasePool } from "@guffsuff/database";
import { PhoneNumberService } from "./phone-number.service.js";
import { OtpService } from "./otp.service.js";
import { SessionService } from "./session.service.js";
import { AccountService } from "./account.service.js";
import { DeviceService } from "./device.service.js";
import { RegistrationLockService } from "./registration-lock.service.js";
import { JwtAuthGuard } from "./jwt-auth.guard.js";
import { AuthController } from "./auth.controller.js";
import { AccountController } from "./account.controller.js";
import { DevicesController } from "./devices.controller.js";
import { UsernamesController } from "./usernames.controller.js";
import { RegistrationLockController } from "./registration-lock.controller.js";

const dbPoolProvider = {
  provide: "DATABASE_POOL",
  useFactory: () => createDatabasePool()
};

const phoneServiceProvider = {
  provide: "PHONE_NUMBER_SERVICE",
  useClass: PhoneNumberService
};

const otpServiceProvider = {
  provide: "OTP_SERVICE",
  useFactory: (pool: any) => new OtpService(pool),
  inject: ["DATABASE_POOL"]
};

const sessionServiceProvider = {
  provide: "SESSION_SERVICE",
  useFactory: (pool: any) => new SessionService(pool),
  inject: ["DATABASE_POOL"]
};

const accountServiceProvider = {
  provide: "ACCOUNT_SERVICE",
  useFactory: (pool: any, sessionService: any) => new AccountService(pool, sessionService),
  inject: ["DATABASE_POOL", "SESSION_SERVICE"]
};

const deviceServiceProvider = {
  provide: "DEVICE_SERVICE",
  useFactory: (pool: any) => new DeviceService(pool),
  inject: ["DATABASE_POOL"]
};

const registrationLockServiceProvider = {
  provide: "REGISTRATION_LOCK_SERVICE",
  useFactory: (pool: any) => new RegistrationLockService(pool),
  inject: ["DATABASE_POOL"]
};

@Module({
  controllers: [
    AuthController,
    AccountController,
    DevicesController,
    UsernamesController,
    RegistrationLockController
  ],
  providers: [
    dbPoolProvider,
    phoneServiceProvider,
    otpServiceProvider,
    sessionServiceProvider,
    accountServiceProvider,
    deviceServiceProvider,
    registrationLockServiceProvider,
    JwtAuthGuard
  ],
  exports: [
    "PHONE_NUMBER_SERVICE",
    "OTP_SERVICE",
    "SESSION_SERVICE",
    "ACCOUNT_SERVICE",
    "DEVICE_SERVICE",
    "REGISTRATION_LOCK_SERVICE",
    "DATABASE_POOL",
    JwtAuthGuard
  ]
})
export class IdentityModule {}

