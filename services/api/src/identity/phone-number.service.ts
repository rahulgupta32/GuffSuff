import { parsePhoneNumberWithError, CountryCode } from "libphonenumber-js";
import * as crypto from "crypto";

const NEPALI_NUMERAL_MAP: Record<string, string> = {
  "०": "0", "१": "1", "२": "2", "३": "3", "४": "4",
  "५": "5", "६": "6", "७": "7", "८": "8", "९": "9"
};

export function convertNepaliNumeralsToAscii(input: string): string {
  return input.replace(/[०-९]/g, (match) => NEPALI_NUMERAL_MAP[match] || match);
}

export function maskPhoneNumber(e164Phone: string): string {
  if (e164Phone.length <= 6) return "***";
  const prefix = e164Phone.slice(0, 5);
  const suffix = e164Phone.slice(-4);
  return `${prefix}****${suffix}`;
}

export class PhoneNumberService {
  private readonly phonePepper: string;
  private readonly aesKey: Buffer;

  constructor() {
    this.phonePepper = process.env.PHONE_HMAC_PEPPER || "default_guffsuff_phone_pepper_v1_32chars_len";
    const secret = process.env.PHONE_ENCRYPTION_SECRET || "default_guffsuff_phone_aes_key_32bytes!!";
    this.aesKey = crypto.createHash("sha256").update(secret).digest();
  }

  public normalizeToE164(input: string, defaultCountry: CountryCode = "NP"): string {
    const asciiInput = convertNepaliNumeralsToAscii(input.trim());
    try {
      const phoneNumber = parsePhoneNumberWithError(asciiInput, defaultCountry);
      if (!phoneNumber.isValid()) {
        throw new Error("Invalid phone number format for country " + defaultCountry);
      }
      return phoneNumber.number;
    } catch (err: any) {
      throw new Error(`Phone number normalization failed: ${err.message}`);
    }
  }

  public generateBlindIndex(e164Phone: string): string {
    return crypto
      .createHmac("sha256", this.phonePepper)
      .update(e164Phone)
      .digest("hex");
  }

  public encryptPhoneNumber(e164Phone: string): Buffer {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv("aes-256-gcm", this.aesKey, iv);
    const encrypted = Buffer.concat([cipher.update(e164Phone, "utf8"), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, encrypted]);
  }

  public decryptPhoneNumber(encryptedBuffer: Buffer): string {
    const iv = encryptedBuffer.subarray(0, 12);
    const tag = encryptedBuffer.subarray(12, 28);
    const ciphertext = encryptedBuffer.subarray(28);
    const decipher = crypto.createDecipheriv("aes-256-gcm", this.aesKey, iv);
    decipher.setAuthTag(tag);
    return decipher.update(ciphertext) + decipher.final("utf8");
  }
}
