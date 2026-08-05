/**
 * @file packages/otp-simulator/src/index.ts
 * @description Isolated Development OTP Simulator for GuffSuff.
 * 
 * SECURITY NOTICE:
 * This package MUST ONLY be imported and bundled in local development and test environments.
 * Attempts to initialize this simulator in staging or production will throw an unrecoverable Error.
 */

export interface SimulatorOtpRecord {
  challengeId: string;
  phoneBlindIndex: string;
  otpCode: string;
  createdAt: Date;
}

class DevelopmentOtpSimulatorService {
  private static instance: DevelopmentOtpSimulatorService;
  private simulatorStore = new Map<string, SimulatorOtpRecord>();

  private constructor() {
    const env = process.env.NODE_ENV || "development";
    if (env === "production" || env === "staging") {
      throw new Error(
        "[FATAL-SECURITY-VIOLATION] DevelopmentOtpSimulator package cannot be initialized in staging or production environments!"
      );
    }
  }

  public static getInstance(): DevelopmentOtpSimulatorService {
    if (!DevelopmentOtpSimulatorService.instance) {
      DevelopmentOtpSimulatorService.instance = new DevelopmentOtpSimulatorService();
    }
    return DevelopmentOtpSimulatorService.instance;
  }

  public recordSimulatorOtp(challengeId: string, phoneBlindIndex: string, otpCode: string): void {
    this.simulatorStore.set(challengeId, {
      challengeId,
      phoneBlindIndex,
      otpCode,
      createdAt: new Date()
    });
    // Log ONLY to isolated development channel, never to normal app loggers
    if (process.env.NODE_ENV === "development") {
      console.log(`\n======================================================`);
      console.log(`[DEV-OTP-SIMULATOR] Challenge: ${challengeId}`);
      console.log(`[DEV-OTP-SIMULATOR] OTP Code: ${otpCode}`);
      console.log(`======================================================\n`);
    }
  }

  public getSimulatorOtp(challengeId: string): string | undefined {
    return this.simulatorStore.get(challengeId)?.otpCode;
  }

  public clear(): void {
    this.simulatorStore.clear();
  }
}

export function getDevelopmentOtpSimulator(): DevelopmentOtpSimulatorService {
  return DevelopmentOtpSimulatorService.getInstance();
}
