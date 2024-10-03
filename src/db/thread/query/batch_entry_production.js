import { desc, eq, sql } from 'drizzle-orm';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';

import db from '../../index.js';
import { batch_entry, batch_entry_production } from '../schema.js';

import * as hrSchema from '../../hr/schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const resultPromise = db
		.insert(batch_entry_production)
		.values(req.body)
		.returning({ insertedId: batch_entry_production.uuid });

	try {
		const data = await resultPromise;

		const toast = {
			status: 201,
			type: 'insert',
			message: `${data[0].insertedId} inserted`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const resultPromise = db
		.update(batch_entry_production)
		.set(req.body)
		.where(eq(batch_entry_production.uuid, req.params.uuid))
		.returning({ updatedId: batch_entry_production.uuid });

	try {
		const data = await resultPromise;

		const toast = {
			status: 201,
			type: 'update',
			message: `${data[0].updatedId} updated`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	const resultPromise = db
		.delete(batch_entry_production)
		.where(eq(batch_entry_production.uuid, req.params.uuid))
		.returning({ deletedId: batch_entry_production.uuid });

	try {
		const data = await resultPromise;

		const toast = {
			status: 201,
			type: 'delete',
			message: `${data[0].deletedId} deleted`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectAll(req, res, next) {
	const resultPromise = db
		.select({
			uuid: batch_entry_production.uuid,
			batch_entry_uuid: batch_entry_production.batch_entry_uuid,
			production_quantity: batch_entry_production.production_quantity,
			coning_carton_quantity:
				batch_entry_production.coning_carton_quantity,
			created_by: batch_entry_production.created_by,
			created_by_name: hrSchema.users.name,
			created_at: batch_entry_production.created_at,
			updated_at: batch_entry_production.updated_at,
			remarks: batch_entry_production.remarks,
		})
		.from(batch_entry_production)
		.leftJoin(
			hrSchema.users,
			eq(batch_entry_production.created_by, hrSchema.users.uuid)
		)
		.orderBy(desc(batch_entry_production.created_at));

	const toast = {
		status: 200,
		type: 'select all',
		message: 'batch_entry_production list',
	};

	handleResponse({ promise: resultPromise, res, next, ...toast });
}

export async function select(req, res, next) {
	const resultPromise = db
		.select({
			uuid: batch_entry_production.uuid,
			batch_entry_uuid: batch_entry_production.batch_entry_uuid,
			production_quantity: batch_entry_production.production_quantity,
			coning_carton_quantity:
				batch_entry_production.coning_carton_quantity,
			created_by: batch_entry_production.created_by,
			created_by_name: hrSchema.users.name,
			created_at: batch_entry_production.created_at,
			updated_at: batch_entry_production.updated_at,
			remarks: batch_entry_production.remarks,
		})
		.from(batch_entry_production)
		.leftJoin(
			hrSchema.users,
			eq(batch_entry_production.created_by, hrSchema.users.uuid)
		)
		.where(eq(batch_entry_production.uuid, req.params.uuid));

	try {
		const data = await resultPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'batch_entry_production',
		};
		return await res.status(201).json({ toast, data: data[0] });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function getBatchEntryProductionDetails(req, res, next) {
	const query = sql`
	WITH calculated_balance AS (SELECT 
		bep.uuid,
		bep.batch_entry_uuid,
		bep.production_quantity,
		bep.coning_carton_quantity,
		be.batch_uuid,
		CONCAT('TB', to_char(batch.created_at, 'YY'), '-', LPAD(batch.id::text, 4, '0')) as batch_number,
		be.order_entry_uuid, 
		CONCAT('TO', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0')) as order_number,
	    oe.color as color,
		oe.po as po,
		oe.style as style,
		oe.bleaching as bleaching,
		oe.count_length_uuid as count_length_uuid,
		CONCAT(cl.count, '/', cl.length) as count_length,
		cl.cone_per_carton,
		be.quantity as batch_quantity,
		be.coning_production_quantity,
		be.coning_carton_quantity,
		be.transfer_quantity as transfer_quantity,
		(be.quantity - be.coning_production_quantity) as coning_balance_quantity,
		(be.quantity - be.transfer_quantity) as balance_quantity,
		bep.created_by,
		users.name as created_by_name,
		bep.created_at,
		bep.updated_at,
		bep.remarks as production_remarks
		
	FROM
		thread.batch_entry_production bep
	LEFT JOIN
		hr.users ON bep.created_by = users.uuid
	LEFT JOIN
		thread.batch_entry be ON bep.batch_entry_uuid = be.uuid
	LEFT JOIN 
		thread.order_entry oe ON be.order_entry_uuid = oe.uuid
	LEFT JOIN
		thread.count_length cl ON oe.count_length_uuid = cl.uuid
	LEFT JOIN 
		thread.order_info ON oe.order_info_uuid = order_info.uuid
	LEFT JOIN
		thread.batch ON be.batch_uuid = batch.uuid
)
	SELECT * FROM calculated_balance
WHERE balance_quantity >= 0;
	`;

	const resultPromise = db.execute(query);
	try {
		const data = await resultPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'batch_entry_production_details list',
		};
		return await res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}