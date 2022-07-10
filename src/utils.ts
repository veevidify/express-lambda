export const errors = {
	INVALID_JSON: {
		message: "Unable to parse JSON.",
		code: 400,
	},
	NOT_FOUND: {
		message: "Wrong way.",
		code: 404,
	},
} as const;

export type ErrorType = keyof typeof errors;
export type ErrorProperties = typeof errors[ErrorType];

export class ApiError extends Error {
	private _code: number;
	private _prevErr?: Error;

	constructor(errType: ErrorType, prevErr?: Error) {
		const errDetails: ErrorProperties = errors[errType];

		super(errDetails.message);
		this._code = errDetails.code;
		this._prevErr = prevErr;
	}

	get code(): number {
		return this._code;
	}

	get previousError(): Error | undefined {
		return this._prevErr;
	}

	toString(): string {
		return `HTTP Code: ${this.code}. Details: ${this.message}`;
	}
}

export const invariant = (
	assertion: boolean,
	errType: ErrorType
): true | never => {
	if (!assertion) {
		const apiError = new ApiError(errType);
		console.log(apiError.toString());
		throw apiError;
	}
	return true;
};
