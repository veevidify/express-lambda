import express from "express";
import bodyParser from "body-parser";
import path from "path";
import cors from "cors";

import type {
	Application,
	Request,
	Response,
	NextFunction,
	Router,
	ErrorRequestHandler,
} from "express";
import type { AppConfig } from "../config";

import { invariant, ApiError } from "../utils";
import mainController from "./main-controller";

const jsonMiddleware = (
	request: Request,
	response: Response,
	next: NextFunction
) =>
	express.json()(request, response, (error) => {
		invariant(!error, "INVALID_JSON");
		next();
	});

const notFoundMiddleware = (
	request: Request,
	response: Response,
	next: NextFunction
) => {
	invariant(false, "NOT_FOUND");
	next();
};

const handleApiErrorMiddleware = (
	err: unknown,
	request: Request,
	response: Response,
	next: NextFunction
) => {
	if (response.headersSent) {
		return next(err);
	}

	if (err instanceof ApiError) {
		response.status(err.code).send({
			statusCode: err.code,
			message: err.toString(),
		});
	} else {
		response.status(500).send({
			statusCode: 500,
			message: JSON.stringify(err),
		});
	}
};

export const createApplication = (config: AppConfig): Application => {
	const router: Router = express.Router();
	router.get("/main", mainController);

	// === //

	const app: Application = express();
	app.use(bodyParser.urlencoded({ extended: true }));
	app.use(jsonMiddleware);
	app.use("/", router);
	app.use(notFoundMiddleware);
	app.use(handleApiErrorMiddleware);

	return app;
};
