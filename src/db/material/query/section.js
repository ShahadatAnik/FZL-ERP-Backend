import { eq } from 'drizzle-orm';
import { handleResponse, validateRequest } from '../../../util/index.js';
import db from '../../index.js';
import { section } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const sectionPromise = db.insert(section).values(req.body).returning();
	const toast = {
		status: 201,
		type: 'create',
		msg: `${req.body.name} created`,
	};

	handleResponse({ promise: sectionPromise, res, next, ...toast });
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const sectionPromise = db
		.update(section)
		.set(req.body)
		.where(eq(section.uuid, req.params.uuid))
		.returning({ updatedName: section.name });

	sectionPromise
		.then((result) => {
			const toast = {
				status: 201,
				type: 'update',
				msg: `${result[0].updatedName} updated`,
			};

			handleResponse({
				promise: sectionPromise,
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
				msg: `Error updating section - ${error.message}`,
			};

			handleResponse({
				promise: sectionPromise,
				res,
				next,
				...toast,
			});
		});
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const sectionPromise = db
		.delete(section)
		.where(eq(section.uuid, req.params.uuid))
		.returning({ deletedName: section.name });

	sectionPromise
		.then((result) => {
			const toast = {
				status: 201,
				type: 'delete',
				msg: `${result[0].deletedName} deleted`,
			};

			handleResponse({
				promise: sectionPromise,
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
				msg: `Error deleting section - ${error.message}`,
			};

			handleResponse({
				promise: sectionPromise,
				res,
				next,
				...toast,
			});
		});
}

export async function selectAll(req, res, next) {
	const resultPromise = db.select().from(section);
	const toast = {
		status: 200,
		type: 'select_all',
		msg: 'Section list',
	};

	handleResponse({ promise: resultPromise, res, next, ...toast });
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const sectionPromise = db
		.select()
		.from(section)
		.where(eq(section.uuid, req.params.uuid));
	const toast = {
		status: 200,
		type: 'select',
		msg: 'Section',
	};

	handleResponse({ promise: sectionPromise, res, next, ...toast });
}
