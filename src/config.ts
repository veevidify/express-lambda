export const config = {
	appEnv: process.env.APP_ENV || "dev",
	httpPort: process.env.HTTP_PORT || 8080,
};

export type AppConfig = typeof config;
