const { defineConfig, loadEnv } = require("@medusajs/utils");

loadEnv(process.env.NODE_ENV || "development", process.cwd());

// CORS when consuming Medusa from admin
// Medusa's docs are added for a better learning experience. Feel free to remove.
const ADMIN_CORS = `${
	process.env.ADMIN_CORS?.length
		? `${process.env.ADMIN_CORS},`
		: "http://localhost:7000,http://localhost:7001,"
}https://docs.medusajs.com`;

// CORS to avoid issues when consuming Medusa from a client
// Medusa's docs are added for a better learning experience. Feel free to remove.
const STORE_CORS = `${
	process.env.STORE_CORS?.length
		? `${process.env.STORE_CORS},`
		: "http://localhost:3000,"
}https://docs.medusajs.com`;

module.exports = defineConfig({
	projectConfig: {
		databaseUrl: process.env.DATABASE_URL,
		// Needed to avoid server does not support SSL error
		databaseDriverOptions: {
			connection: {
				ssl: false,
			},
		},
		http: {
			storeCors: STORE_CORS,
			adminCors: ADMIN_CORS,
			authCors: process.env.AUTH_CORS || ADMIN_CORS,
			jwtSecret: process.env.JWT_SECRET || "supersecret",
			cookieSecret: process.env.COOKIE_SECRET || "supersecret",
		},
	},
});
