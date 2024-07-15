import {
	decimal,
	integer,
	pgSchema,
	text,
	timestamp,
	uuid,
} from "drizzle-orm/pg-core";

import { users } from "../hr/schema.js";
import { info } from "../material/schema.js";

const purchase = pgSchema("purchase");

export const vendor = purchase.table("vendor", {
	uuid: uuid("uuid").primaryKey(),
	name: text("name").notNull(),
	contact_name: text("contact_name"),
	email: text("email").default(""),
	office_address: text("office_address").default(""),
	contact_number: text("contact_number").default(""),
	remarks: text("remarks"),
});

export const defPurchaseVendor = {
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
		contact_name: {
			type: "string",
		},
		email: {
			type: "string",
		},
		office_address: {
			type: "string",
		},
		contact_number: {
			type: "string",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Purchase/Vendor",
	},
};

export const description = purchase.table("description", {
	uuid: uuid("uuid").primaryKey(),
	vendor_uuid: uuid("vendor_uuid").references(() => vendor.uuid),
	is_local: integer("is_local").default(0),
	lc_number: text("lc_number").default(null),
	created_by: uuid("created_by").references(() => users.uuid),
	created: timestamp("created"),
	updated: timestamp("updated").default(null),
	remarks: text("remarks"),
});

export const defPurchaseDescription = {
	type: "object",
	required: ["uuid", "vendor_uuid", "created_by", "created"],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		vendor_uuid: {
			type: "string",
			format: "uuid",
		},
		is_local: {
			type: "integer",
		},
		lc_number: {
			type: "string",
		},
		created_by: {
			type: "string",
			format: "uuid",
		},
		created: {
			type: "string",
		},
		updated: {
			type: "string",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Purchase/Description",
	},
};

export const entry = purchase.table("entry", {
	uuid: uuid("uuid").primaryKey(),
	purchase_description_uuid: uuid("purchase_description_uuid").references(
		() => description.uuid
	),
	material_info_uuid: uuid("material_info_uuid").references(() => info.uuid),
	quantity: decimal("quantity").notNull(),
	price: decimal("price").notNull(),
	created_by: uuid("created_by").references(() => users.uuid),
	created: timestamp("created"),
	updated: timestamp("updated").default(null),
	remarks: text("remarks"),
});

export const defPurchaseEntry = {
	type: "object",
	required: [
		"uuid",
		"purchase_description_uuid",
		"material_info_uuid",
		"quantity",
		"price",
		"created_by",
		"created",
	],
	properties: {
		uuid: {
			type: "string",
			format: "uuid",
		},
		purchase_description_uuid: {
			type: "string",
			format: "uuid",
		},
		material_info_uuid: {
			type: "string",
			format: "uuid",
		},
		quantity: {
			type: "number",
		},
		price: {
			type: "number",
		},
		created_by: {
			type: "string",
			format: "uuid",
		},
		created: {
			type: "string",
		},
		updated: {
			type: "string",
		},
		remarks: {
			type: "string",
		},
	},
	xml: {
		name: "Purchase/Entry",
	},
};

export const defPurchase = {
	vendor: defPurchaseVendor,
	description: defPurchaseDescription,
	entry: defPurchaseEntry,
};

export const tagPurchase = [
	{
		"purchase.vendor": {
			name: "Vendor",
			description: "Vendor",
		},
	},
	{
		"purchase.description": {
			name: "Description",
			description: "Description",
		},
	},
	{
		"purchase.entry": {
			name: "Entry",
			description: "Entry",
		},
	},
];

export default purchase;
