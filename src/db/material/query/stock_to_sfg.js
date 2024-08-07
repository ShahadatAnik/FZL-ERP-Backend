import { eq } from 'drizzle-orm';
import { handleResponse, validateRequest } from '../../../util/index.js';
import * as hrSchema from '../../hr/schema.js';
import db from '../../index.js';
import * as zipperSchema from '../../zipper/schema.js';
import { stock_to_sfg } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const usedPromise = db.insert(stock_to_sfg).values(req.body).returning();
	const toast = {
		status: 201,
		type: 'create',
		msg: `${req.body.name} created`,
	};
	handleResponse({ promise: usedPromise, res, next, ...toast });
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const usedPromise = db
		.update(stock_to_sfg)
		.set(req.body)
		.where(eq(stock_to_sfg.uuid, req.params.uuid))
		.returning({ updatedName: stock_to_sfg.name });

	usedPromise
		.then((result) => {
			const toast = {
				status: 201,
				type: 'update',
				msg: `${result[0].updatedName} updated`,
			};

			handleResponse({
				promise: usedPromise,
				res,
				next,
				...toast,
			});
		})
		.catch((error) => {
			console.error(error);

			const toast = {
				status: 500,
				type: 'update',
				msg: `Error updating stock_to_sfg - ${error.message}`,
			};

			handleResponse({
				promise: usedPromise,
				res,
				next,
				...toast,
			});
		});
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const usedPromise = db
		.delete(stock_to_sfg)
		.where(eq(stock_to_sfg.uuid, req.params.uuid))
		.returning({ deletedName: stock_to_sfg.name });

	usedPromise
		.then((result) => {
			const toast = {
				status: 201,
				type: 'delete',
				msg: `${result[0].deletedName} deleted`,
			};

			handleResponse({
				promise: usedPromise,
				res,
				next,
				...toast,
			});
		})
		.catch((error) => {
			console.error(error);

			const toast = {
				status: 500,
				type: 'delete',
				msg: `Error deleting stock_to_sfg - ${error.message}`,
			};

			handleResponse({
				promise: usedPromise,
				res,
				next,
				...toast,
			});
		});
}

export async function selectAll(req, res, next) {
	const resultPromise = db
		.select({
			uuid: stock_to_sfg.uuid,
			material_uuid: stock_to_sfg.material_uuid,
			material_name: info.name,
			order_entry_uuid: stock_to_sfg.order_entry_uuid,
			order_description_uuid:
				zipperSchema.order_entry.order_description_uuid,
			trx_to: stock_to_sfg.trx_to,
			trx_quantity: stock_to_sfg.trx_quantity,
			created_by: stock_to_sfg.created_by,
			user_name: hrSchema.users.name,
			user_designation: hrSchema.designation.designation,
			user_department: hrSchema.department.department,
			created_at: stock_to_sfg.created_at,
			updated_at: stock_to_sfg.updated_at,
			remarks: stock_to_sfg.remarks,
		})
		.from(stock_to_sfg)
		.leftJoin(info)
		.on(stock_to_sfg.material_uuid.equals(info.uuid))
		.leftJoin(zipperSchema.order_entry)
		.on(stock_to_sfg.order_entry_uuid.equals(zipperSchema.order_entry.uuid))
		.leftJoin(zipperSchema.order_description)
		.on(
			stock_to_sfg.order_description_uuid.equals(
				zipperSchema.order_description.uuid
			)
		)
		.leftJoin(hrSchema.users)
		.on(stock_to_sfg.created_by.equals(hrSchema.users.uuid))
		.leftJoin(hrSchema.designation)
		.on(hrSchema.users.designation_uuid.equals(hrSchema.designation.uuid))
		.leftJoin(hrSchema.department)
		.on(hrSchema.users.department_uuid.equals(hrSchema.department.uuid));

	const toast = {
		status: 200,
		type: 'select_all',
		msg: 'Stock to SFG list',
	};

	handleResponse({ promise: resultPromise, res, next, ...toast });
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const usedPromise = db
		.select({
			uuid: stock_to_sfg.uuid,
			material_uuid: stock_to_sfg.material_uuid,
			material_name: info.name,
			order_entry_uuid: stock_to_sfg.order_entry_uuid,
			order_description_uuid:
				zipperSchema.order_entry.order_description_uuid,
			trx_to: stock_to_sfg.trx_to,
			trx_quantity: stock_to_sfg.trx_quantity,
			created_by: stock_to_sfg.created_by,
			user_name: hrSchema.users.name,
			user_designation: hrSchema.designation.designation,
			user_department: hrSchema.department.department,
			created_at: stock_to_sfg.created_at,
			updated_at: stock_to_sfg.updated_at,
			remarks: stock_to_sfg.remarks,
		})
		.from(stock_to_sfg)
		.leftJoin(info)
		.on(stock_to_sfg.material_uuid.equals(info.uuid))
		.leftJoin(zipperSchema.order_entry)
		.on(stock_to_sfg.order_entry_uuid.equals(zipperSchema.order_entry.uuid))
		.leftJoin(zipperSchema.order_description)
		.on(
			stock_to_sfg.order_description_uuid.equals(
				zipperSchema.order_description.uuid
			)
		)
		.leftJoin(hrSchema.users)
		.on(stock_to_sfg.created_by.equals(hrSchema.users.uuid))
		.leftJoin(hrSchema.designation)
		.on(hrSchema.users.designation_uuid.equals(hrSchema.designation.uuid))
		.leftJoin(hrSchema.department)
		.on(hrSchema.users.department_uuid.equals(hrSchema.department.uuid))
		.where(eq(stock_to_sfg.uuid, req.params.uuid));
	const toast = {
		status: 200,
		type: 'select',
		msg: 'Stock to SFG',
	};

	handleResponse({ promise: usedPromise, res, next, ...toast });
}
