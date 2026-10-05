import { getDevelopmentOtpSimulator } from "@guffsuff/otp-simulator";

export interface OtpDeliveryResult {
  success: boolean;
  providerName: string;
  providerRequestId?: string;
  costAmount: number | null;
  costCurrency: string | null;
  errorCode?: string;
}

export interface OtpProvider {
  sendOtp(
    challengeId: string,
    phoneBlindIndex: string,
    otpCode: string,
    destination?: string
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
  constructor(private readonly request: typeof fetch = fetch) {}
  public async sendOtp(
    _challengeId: string,
    _phoneBlindIndex: string,
    otpCode: string,
    destination?: string
  ): Promise<OtpDeliveryResult> {
    const sid = process.env.TWILIO_ACCOUNT_SID;
    const token = process.env.TWILIO_AUTH_TOKEN;
    const sender = process.env.TWILIO_MESSAGING_SERVICE_SID;
    if (
      process.env.SMS_PROVIDER !== "twilio" ||
      !sid ||
      !/^AC[0-9a-fA-F]{32}$/.test(sid) ||
      !token ||
      !sender ||
      !/^MG[0-9a-fA-F]{32}$/.test(sender)
    ) {
      throw new Error("Production SMS configuration is missing or invalid");
    }
    if (!destination || !/^\+9779\d{9}$/.test(destination) || !/^\d{6}$/.test(otpCode)) {
      throw new Error("Invalid OTP SMS destination or code");
    }
    const failure = (errorCode: string): OtpDeliveryResult => ({
      success: false,
      providerName: "TWILIO",
      costAmount: null,
      costCurrency: null,
      errorCode
    });
    try {
      const response = await this.request(
        `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
        {
          method: "POST",
          redirect: "error",
          signal: AbortSignal.timeout(10000),
          headers: {
            Authorization: `Basic ${Buffer.from(`${sid}:${token}`).toString("base64")}`,
            "Content-Type": "application/x-www-form-urlencoded"
          },
          body: new URLSearchParams({
            To: destination,
            MessagingServiceSid: sender,
            Body: `गफसफ verification code: ${otpCode}. Expires in 5 minutes.`
          }).toString()
        }
      );
      if (!response.ok) return failure(`HTTP_${response.status}`);
      const data = (await response.json()) as { sid?: string; status?: string };
      if (
        !data.sid ||
        !/^SM[0-9a-fA-F]{32}$/.test(data.sid) ||
        !["accepted", "queued", "sending", "sent", "delivered"].includes(data.status ?? "")
      ) {
        return failure("INVALID_PROVIDER_RESPONSE");
      }
      return {
        success: true,
        providerName: "TWILIO",
        providerRequestId: data.sid,
        costAmount: null,
        costCurrency: null
      };
    } catch (_) {
      return failure("PROVIDER_UNAVAILABLE");
    }
  }
}
