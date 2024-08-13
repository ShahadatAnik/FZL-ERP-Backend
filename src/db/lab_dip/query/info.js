import { eq, sql } from 'drizzle-orm';
import { createApi } from '../../../util/api.js';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import * as hrSchema from '../../hr/schema.js';
import db from '../../index.js';
import * as publicSchema from '../../public/schema.js';
import * as zipperSchema from '../../zipper/schema.js';
import { info, recipe } from '../schema.js';

export async function insert(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const { recipe_uuid } = req.body;

	const infoPromise = db
		.insert(info)
		.values(req.body)
		.returning({ insertedName: info.name, insertedId: info.uuid });

	try {
		const data = await infoPromise;

		const recipePromise = db
			.update(recipe)
			.set({ lab_dip_info_uuid: data[0].insertedId })
			.where(eq(recipe.uuid, recipe_uuid))
			.returning({ updatedName: recipe.name });

		const recipeData = await recipePromise;

		if (!recipeData.length) {
			const error = {
				status: 500,
				type: 'insert',
				message: 'Recipe not updated',
			};

			return await handleError({ error, res });
		}

		const toast = {
			status: 201,
			type: 'insert',
			message: `${data[0].insertedName} inserted`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function update(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	try {
		// Step 1: Fetch existing recipes
		const existingRecipesPromise = await db
			.select(recipe)
			.from(info)
			.where(eq(recipe.lab_dip_info_uuid, req.params.uuid));

		const existingRecipes =
			(await existingRecipesPromise[0].recipe_uuid) || [];

		// Step 2: Perform the update operation
		const infoPromise = db
			.update(info)
			.set(req.body)
			.where(eq(info.uuid, req.params.uuid))
			.returning({ updatedName: info.name });

		const data = await infoPromise;

		// Step 3: Compare existing recipes with updated recipes
		const updatedRecipes = req.body.recipe || [];
		const removedRecipes = existingRecipes.filter(
			(recipe) => !updatedRecipes.includes(recipe)
		);

		// Step 4: Handle removed recipes (e.g., log them)
		if (removedRecipes.length > 0) {
			const removedRecipePromise = db
				.update(recipe)
				.set({ lab_dip_info_uuid: null })
				.where(eq(recipe.uuid, removedRecipes))
				.returning({ updatedName: recipe.name });

			const removedRecipeData = await removedRecipePromise;

			if (!removedRecipeData.length) {
				const error = {
					status: 500,
					type: 'update',
					message: 'Recipe not updated',
				};

				return await handleError({ error, res });
			}
		}

		// Step 5: Return the response
		const toast = {
			status: 201,
			type: 'update',
			message: `${data[0].updatedName} updated`,
		};

		return await res.status(201).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function remove(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const infoPromise = db
		.delete(info)
		.where(eq(info.uuid, req.params.uuid))
		.returning({ deletedName: info.name, deletedId: info.uuid });

	try {
		const data = await infoPromise;

		const recipePromise = db
			.update(recipe)
			.set({ lab_dip_info_uuid: null })
			.where(eq(recipe.lab_dip_info_uuid, data[0].deletedId))
			.returning({ updatedName: recipe.name });

		const recipeData = await recipePromise;

		if (!recipeData.length) {
			const error = {
				status: 500,
				type: 'delete',
				message: 'Recipe not updated',
			};

			return await handleError({ error, res });
		}

		const toast = {
			status: 200,
			type: 'delete',
			message: `${data[0].deletedName} deleted`,
		};

		return await res.status(200).json({ toast, data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectAll(req, res, next) {
	const resultPromise = db
		.select({
			uuid: info.uuid,
			id: info.id,
			info_id: sql`concat('LDI', to_char(info.created_at, 'YY'), '-', LPAD(info.id::text, 4, '0'))`,
			name: info.name,
			order_info_uuid: info.order_info_uuid,
			buyer_uuid: zipperSchema.order_info.buyer_uuid,
			buyer_name: publicSchema.buyer.name,
			party_uuid: zipperSchema.order_info.party_uuid,
			party_name: publicSchema.party.name,
			marketing_uuid: zipperSchema.order_info.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			merchandiser_uuid: zipperSchema.order_info.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: zipperSchema.order_info.factory_uuid,
			factory_name: publicSchema.factory.name,
			lab_status: info.lab_status,
			created_by: info.created_by,
			created_by_name: hrSchema.users.name,
			created_at: info.created_at,
			updated_at: info.updated_at,
			remarks: info.remarks,
		})
		.from(info)
		.leftJoin(
			zipperSchema.order_info,
			eq(info.order_info_uuid, zipperSchema.order_info.uuid)
		)
		.leftJoin(hrSchema.users, eq(info.created_by, hrSchema.users.uuid))
		.leftJoin(
			publicSchema.buyer,
			eq(zipperSchema.order_info.buyer_uuid, publicSchema.buyer.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(zipperSchema.order_info.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.marketing,
			eq(
				zipperSchema.order_info.marketing_uuid,
				publicSchema.marketing.uuid
			)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(
				zipperSchema.order_info.merchandiser_uuid,
				publicSchema.merchandiser.uuid
			)
		)
		.leftJoin(
			publicSchema.factory,
			eq(zipperSchema.order_info.factory_uuid, publicSchema.factory.uuid)
		);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Info list',
	};
	handleResponse({ promise: resultPromise, res, next, ...toast });
}

export async function select(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const infoPromise = db
		.select({
			uuid: info.uuid,
			id: info.id,
			info_id: sql`concat('LDI', to_char(info.created_at, 'YY'), '-', LPAD(info.id::text, 4, '0'))`,
			name: info.name,
			order_info_uuid: info.order_info_uuid,
			buyer_uuid: zipperSchema.order_info.buyer_uuid,
			buyer_name: publicSchema.buyer.name,
			party_uuid: zipperSchema.order_info.party_uuid,
			party_name: publicSchema.party.name,
			marketing_uuid: zipperSchema.order_info.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			merchandiser_uuid: zipperSchema.order_info.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: zipperSchema.order_info.factory_uuid,
			factory_name: publicSchema.factory.name,
			lab_status: info.lab_status,
			created_by: info.created_by,
			created_by_name: hrSchema.users.name,
			created_at: info.created_at,
			updated_at: info.updated_at,
			remarks: info.remarks,
		})
		.from(info)
		.leftJoin(
			zipperSchema.order_info,
			eq(info.order_info_uuid, zipperSchema.order_info.uuid)
		)
		.leftJoin(hrSchema.users, eq(info.created_by, hrSchema.users.uuid))
		.leftJoin(
			publicSchema.buyer,
			eq(zipperSchema.order_info.buyer_uuid, publicSchema.buyer.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(zipperSchema.order_info.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.marketing,
			eq(
				zipperSchema.order_info.marketing_uuid,
				publicSchema.marketing.uuid
			)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(
				zipperSchema.order_info.merchandiser_uuid,
				publicSchema.merchandiser.uuid
			)
		)
		.leftJoin(
			publicSchema.factory,
			eq(zipperSchema.order_info.factory_uuid, publicSchema.factory.uuid)
		)
		.where(eq(info.uuid, req.params.uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Info',
	};
	handleResponse({ promise: infoPromise, res, next, ...toast });
}

export async function selectInfoByLabDipInfoUuid(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const infoPromise = db
		.select({
			uuid: info.uuid,
			id: info.id,
			info_id: sql`concat('LDI', to_char(info.created_at, 'YY'), '-', LPAD(info.id::text, 4, '0'))`,
			name: info.name,
			order_info_uuid: info.order_info_uuid,
			buyer_uuid: zipperSchema.order_info.buyer_uuid,
			buyer_name: publicSchema.buyer.name,
			party_uuid: zipperSchema.order_info.party_uuid,
			party_name: publicSchema.party.name,
			marketing_uuid: zipperSchema.order_info.marketing_uuid,
			marketing_name: publicSchema.marketing.name,
			merchandiser_uuid: zipperSchema.order_info.merchandiser_uuid,
			merchandiser_name: publicSchema.merchandiser.name,
			factory_uuid: zipperSchema.order_info.factory_uuid,
			factory_name: publicSchema.factory.name,
			lab_status: info.lab_status,
			created_by: info.created_by,
			created_by_name: hrSchema.users.name,
			created_at: info.created_at,
			updated_at: info.updated_at,
			remarks: info.remarks,
		})
		.from(info)
		.leftJoin(
			zipperSchema.order_info,
			eq(info.order_info_uuid, zipperSchema.order_info.uuid)
		)
		.leftJoin(hrSchema.users, eq(info.created_by, hrSchema.users.uuid))
		.leftJoin(
			publicSchema.buyer,
			eq(zipperSchema.order_info.buyer_uuid, publicSchema.buyer.uuid)
		)
		.leftJoin(
			publicSchema.party,
			eq(zipperSchema.order_info.party_uuid, publicSchema.party.uuid)
		)
		.leftJoin(
			publicSchema.marketing,
			eq(
				zipperSchema.order_info.marketing_uuid,
				publicSchema.marketing.uuid
			)
		)
		.leftJoin(
			publicSchema.merchandiser,
			eq(
				zipperSchema.order_info.merchandiser_uuid,
				publicSchema.merchandiser.uuid
			)
		)
		.leftJoin(
			publicSchema.factory,
			eq(zipperSchema.order_info.factory_uuid, publicSchema.factory.uuid)
		)
		.where(eq(info.uuid, req.params.lab_dip_info_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Info',
	};
	handleResponse({ promise: infoPromise, res, next, ...toast });
}

export async function selectInfoRecipeByLabDipInfoUuid(req, res, next) {
	if (!validateRequest(req, next)) return;

	const { lab_dip_info_uuid } = req.params;

	try {
		const api = await createApi(req);
		const fetchData = async (endpoint) =>
			await api
				.get(`${endpoint}/by/${lab_dip_info_uuid}`)
				.then((response) => response);

		const [info, recipe] = await Promise.all([
			fetchData('/lab-dip/info'),
			fetchData('/lab-dip/info-recipe'),
		]);

		const response = {
			...info?.data?.data[0],
			recipe: recipe?.data?.data || [],
		};

		const toast = {
			status: 200,
			type: 'select',
			msg: 'Recipe Details Full',
		};

		res.status(200).json({ toast, data: response });
	} catch (error) {
		await handleError({ error, res });
	}
}
