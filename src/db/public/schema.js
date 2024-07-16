import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

import * as hrSchema from "../hr/schema.js";

export const buyer = pgTable("buyer", {
	uuid: uuid("uuid").primaryKey(),
	name: text("name"),
	short_name: text("short_name"),
	remarks: text("remarks"),
});

export const defPublicBuyer = {
	type: "object",
	required: ["uuid", "name"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		name: {
			type: "string",
		},
		short_name: {
			type: "string",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Public/Buyer",
	},
};

export const party = pgTable("party", {
	uuid: uuid("uuid").primaryKey(),
	name: text("name"),
	short_name: text("short_name"),
	remarks: text("remarks"),
});

export const defPublicParty = {
	type: "object",
	required: ["uuid", "name"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		name: {
			type: "string",
		},
		short_name: {
			type: "string",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Public/Party",
	},
};

export const marketing = pgTable("marketing", {
	uuid: uuid("uuid").primaryKey(),
	name: text("name"),
	short_name: text("short_name"),
	user_uuid: uuid("user_uuid").references(() => hrSchema.users.uuid),
	remarks: text("remarks"),
});

export const defPublicMarketing = {
	type: "object",
	required: ["uuid", "name", "user_uuid"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		name: {
			type: "string",
		},
		short_name: {
			type: "string",
		},
		user_uuid: {
			type: "string",
			format: "uuid",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Public/Marketing",
	},
};

export const merchandiser = pgTable("merchandiser", {
	uuid: uuid("uuid").primaryKey(),
	party_uuid: uuid("party_uuid").references(() => party.uuid),
	name: text("name"),
	email: text("email"),
	phone: text("phone"),
	address: text("address"),
	created: timestamp("created"),
	updated: timestamp("updated"),
});

export const defPublicMerchandiser = {
	type: "object",
	required: ["uuid", "party_uuid", "name", "created"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		party_uuid: {
			type: "string",
			format: "uuid",
		},
		name: {
			type: "string",
		},
		email: {
			type: "string",
		},
		phone: {
			type: "string",
		},
		address: {
			type: "string",
		},
		created: {
			type: "string",
			format: "date-time",
		},
		updated: {
			type: "string",
			format: "date-time",
		},
	},
	xml: {
		name: "Public/Merchandiser",
	},
};

export const factory = pgTable("factory", {
	uuid: uuid("uuid").primaryKey(),
	party_uuid: uuid("party_uuid").references(() => party.uuid),
	name: text("name"),
	phone: text("phone"),
	address: text("address"),
	created: timestamp("created"),
	updated: timestamp("updated"),
});

export const defPublicFactory = {
	type: "object",
	required: ["uuid", "party_uuid", "name", "created"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		party_uuid: {
			type: "string",
			format: "uuid",
		},
		name: {
			type: "string",
		},
		phone: {
			type: "string",
		},
		address: {
			type: "string",
		},
		created: {
			type: "string",
			format: "date-time",
		},
		updated: {
			type: "string",
			format: "date-time",
		},
	},
	xml: {
		name: "Public/Factory",
	},
};

export const section = pgTable("section", {
	uuid: uuid("uuid").primaryKey(),
	name: text("name"),
	short_name: text("short_name"),
	remarks: text("remarks"),
});

export const defPublicSection = {
	type: "object",
	required: ["uuid", "name"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		name: {
			type: "string",
		},
		short_name: {
			type: "string",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Public/Section",
	},
};

export const properties = pgTable("properties", {
	uuid: uuid("uuid").primaryKey(),
	item_for: text("item_for"),
	type: text("type").unique(),
	name: text("name"),
	short_name: text("short_name"),
	created_by: uuid("created_by").references(() => hrSchema.users.uuid),
	created: timestamp("created"),
	updated: timestamp("updated"),
});

export const defPublicProperties = {
	type: "object",
	required: ["uuid", "type", "name", "created_by", "created"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		item_for: {
			type: "string",
		},
		type: {
			type: "string",
		},
		name: {
			type: "string",
		},
		short_name: {
			type: "string",
		},
		created_by: {
			type: "string",
			format: "uuid",
		},
		created: {
			type: "string",
			format: "date-time",
		},
		updated: {
			type: "string",
			format: "date-time",
		},
	},
	xml: {
		name: "Public/Properties",
	},
};

export const defPublic = {
	buyer: defPublicBuyer,
	party: defPublicParty,
	marketing: defPublicMarketing,
	merchandiser: defPublicMerchandiser,
	factory: defPublicFactory,
	section: defPublicSection,
	properties: defPublicProperties,
};

export const tagPublic = [
	{
		"public.buyer": {
			name: "buyer",
			description: "buyer",
		},
	},
	{
		"public.party": {
			name: "party",
			description: "party",
		},
	},
	{
		"public.marketing": {
			name: "marketing",
			description: "marketing",
		},
	},
	{
		"public.merchandiser": {
			name: "merchandiser",
			description: "merchandiser",
		},
	},
	{
		"public.factory": {
			name: "factory",
			description: "factory",
		},
	},
	{
		"public.section": {
			name: "section",
			description: "section",
		},
	},
	{
		"public.properties": {
			name: "properties",
			description: "properties",
		},
	},
];

export default buyer;
