import { getDevelopmentOtpSimulator } from "@guffsuff/otp-simulator";

export interface OtpDeliveryResult {
  success: boolean;
  providerName: string;
  providerRequestId?: string;
  costAmount: number;
  costCurrency: string;
  errorCode?: string;
}

export interface OtpProvider {
  sendOtp(
    challengeId: string,
    phoneBlindIndex: string,
    otpCode: string
  ): Promise<OtpDeliveryResult>;
}

export class DevelopmentOtpProvider implements OtpProvider {
  constructor() {
    const env = process.env.NODE_ENV || "development";
    if (env === "production" || env === "staging") {
      throw new Error(
        "[FATAL-SECURITY-VIOLATION] DevelopmentOtpProvider cannot be instantiated in staging or production!"
      );
    }
  }

  public async sendOtp(
    challengeId: string,
    phoneBlindIndex: string,
    otpCode: string
  ): Promise<OtpDeliveryResult> {
    const simulator = getDevelopmentOtpSimulator();
    simulator.recordSimulatorOtp(challengeId, phoneBlindIndex, otpCode);
    return {
      success: true,
      providerName: "DEV_SIMULATOR",
      providerRequestId: `sim_${challengeId}`,
      costAmount: 0.0,
      costCurrency: "NPR"
    };
  }
}

export class ProductionOtpProvider implements OtpProvider {
  public async sendOtp(
    _challengeId: string,
    _phoneBlindIndex: string,
    _otpCode: string
  ): Promise<OtpDeliveryResult> {
    throw new Error(
      "[CONFIG-ERROR] No permanent production SMS provider configured. Sparow SMS / Twilio integration requires explicit evaluation."
    );
  }
}
