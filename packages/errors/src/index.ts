export class BaseDomainException extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode: number = 400
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundException extends BaseDomainException {
  constructor(entity: string, id?: string) {
    super("ERR_NOT_FOUND", `${entity}${id ? ` (${id})` : ""} was not found.`, 404);
  }
}

export class UnauthorizedException extends BaseDomainException {
  constructor(reason: string = "Authentication required.") {
    super("ERR_UNAUTHORIZED", reason, 401);
  }
}

export class InvalidConfigurationException extends BaseDomainException {
  constructor(variableName: string, reason: string) {
    super("ERR_INVALID_CONFIG", `Configuration error for ${variableName}: ${reason}`, 500);
  }
}
