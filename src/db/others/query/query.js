import { eq, min, sql, sum } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';

import * as commercialSchema from '../../commercial/schema.js';
import * as deliverySchema from '../../delivery/schema.js';
import * as hrSchema from '../../hr/schema.js';
import * as labDipSchema from '../../lab_dip/schema.js';
import * as materialSchema from '../../material/schema.js';
import * as publicSchema from '../../public/schema.js';
import * as purchaseSchema from '../../purchase/schema.js';
import * as sliderSchema from '../../slider/schema.js';
import * as threadSchema from '../../Thread/schema.js';
import * as zipperSchema from '../../zipper/schema.js';

// * Aliases * //
const itemProperties = alias(publicSchema.properties, 'itemProperties');
const zipperProperties = alias(publicSchema.properties, 'zipperProperties');
const endTypeProperties = alias(publicSchema.properties, 'endTypeProperties');
const pullerTypeProperties = alias(
	publicSchema.properties,
	'pullerTypeProperties'
);

//* public
export async function selectMachine(req, res, next) {
	const machinePromise = db
		.select({
			value: publicSchema.machine.uuid,
			label: publicSchema.machine.name,
			max_capacity: publicSchema.machine.max_capacity,
			min_capacity: publicSchema.machine.min_capacity,
		})
		.from(publicSchema.machine);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Machine list',
	};
	handleResponse({
		promise: machinePromise,
		res,
		next,
		...toast,
	});
}

export async function selectParty(req, res, next) {
	const partyPromise = db
		.select({
			value: publicSchema.party.uuid,
			label: publicSchema.party.name,
		})
		.from(publicSchema.party);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Party list',
	};
	handleResponse({
		promise: partyPromise,
		res,
		next,
		...toast,
	});
}

export async function selectMarketingUser(req, res, next) {
	const userPromise = db
		.select({
			value: hrSchema.users.uuid,
			label: sql`concat(users.name,
				' - ',
				designation.designation)`,
		})
		.from(hrSchema.users)
		.leftJoin(
			hrSchema.designation,
			eq(hrSchema.users.designation_uuid, hrSchema.designation.uuid)
		)
		.leftJoin(
			hrSchema.department,
			eq(hrSchema.designation.department_uuid, hrSchema.department.uuid)
		)
		.where(eq(hrSchema.department.department, 'Sales And Marketing'));

	const toast = {
		status: 200,
		type: 'select',
		message: 'marketing user',
	};

	handleResponse({ promise: userPromise, res, next, ...toast });
}

export async function selectBuyer(req, res, next) {
	const buyerPromise = db
		.select({
			value: publicSchema.buyer.uuid,
			label: publicSchema.buyer.name,
		})
		.from(publicSchema.buyer);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Buyer list',
	};
	handleResponse({
		promise: buyerPromise,
		res,
		next,
		...toast,
	});
}

export function selectSpecificMerchandiser(req, res, next) {
	if (!validateRequest(req, next)) return;

	const merchandiserPromise = db
		.select({
			value: publicSchema.merchandiser.uuid,
			label: publicSchema.merchandiser.name,
		})
		.from(publicSchema.merchandiser)
		.leftJoin(
			publicSchema.party,
			eq(publicSchema.merchandiser.party_uuid, publicSchema.party.uuid)
		)
		.where(eq(publicSchema.party.uuid, req.params.party_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Merchandiser',
	};

	handleResponse({
		promise: merchandiserPromise,
		res,
		next,
		...toast,
	});
}

export function selectSpecificFactory(req, res, next) {
	if (!validateRequest(req, next)) return;

	const factoryPromise = db
		.select({
			value: publicSchema.factory.uuid,
			label: publicSchema.factory.name,
		})
		.from(publicSchema.factory)
		.leftJoin(
			publicSchema.party,
			eq(publicSchema.factory.party_uuid, publicSchema.party.uuid)
		)
		.where(eq(publicSchema.party.uuid, req.params.party_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'Factory',
	};

	handleResponse({
		promise: factoryPromise,
		res,
		next,
		...toast,
	});
}

export function selectMarketing(req, res, next) {
	const marketingPromise = db
		.select({
			value: publicSchema.marketing.uuid,
			label: publicSchema.marketing.name,
		})
		.from(publicSchema.marketing);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Marketing list',
	};
	handleResponse({
		promise: marketingPromise,
		res,
		next,
		...toast,
	});
}

export function selectOrderProperties(req, res, next) {
	if (!validateRequest(req, next)) return;

	const orderPropertiesPromise = db
		.select({
			value: publicSchema.properties.uuid,
			label: publicSchema.properties.name,
		})
		.from(publicSchema.properties)
		.where(eq(publicSchema.properties.type, req.params.type_name));

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Order Properties list',
	};
	handleResponse({
		promise: orderPropertiesPromise,
		res,
		next,
		...toast,
	});
}

// zipper
export function selectOrderInfo(req, res, next) {
	if (!validateRequest(req, next)) return;

	const orderInfoPromise = db
		.select({
			value: zipperSchema.order_info.uuid,
			label: sql`CONCAT('Z', to_char(order_info.created_at, 'YY'), '-', LPAD(order_info.id::text, 4, '0'))`,
		})
		.from(zipperSchema.order_info);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Order Info list',
	};

	handleResponse({
		promise: orderInfoPromise,
		res,
		next,
		...toast,
	});
}

export async function selectOrderZipperThread(req, res, next) {
	if (!validateRequest(req, next)) return;

	const query = sql`SELECT
							oz.uuid AS value,
							CONCAT('Z', to_char(oz.created_at, 'YY'), '-', LPAD(oz.id::text, 4, '0')) as label
						FROM
							zipper.order_info oz
						UNION 
						SELECT
							ot.uuid AS value,
							CONCAT('TO', to_char(ot.created_at, 'YY'), '-', LPAD(ot.id::text, 4, '0')) as label
						FROM
							thread.order_info ot`;

	const orderZipperThreadPromise = db.execute(query);

	try {
		const data = await orderZipperThreadPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Zipper Thread list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderInfoToGetOrderDescription(req, res, next) {
	if (!validateRequest(req, next)) return;

	const { order_number } = req.params;

	const query = sql`SELECT * FROM zipper.v_order_details WHERE v_order_details.order_number = ${order_number}`;

	const orderInfoPromise = db.execute(query);

	try {
		const data = await orderInfoPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Info list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderEntry(req, res, next) {
	const query = sql`SELECT
					oe.uuid AS value,
					CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', oe.style, '/', oe.color, '/', oe.size) AS label,
					oe.quantity AS quantity,
					oe.quantity - (
						COALESCE(sfg.coloring_prod, 0) + COALESCE(sfg.finishing_prod, 0)
					) AS can_trf_quantity
				FROM
					zipper.order_entry oe
					LEFT JOIN zipper.v_order_details_full vodf ON oe.order_description_uuid = vodf.order_description_uuid
					LEFT JOIN zipper.sfg sfg ON sfg.order_entry_uuid = oe.uuid
				`;
	// WHERE oe.swatch_status_enum = 'approved' For development purpose, removed

	const orderEntryPromise = db.execute(query);

	try {
		const data = await orderEntryPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Entry list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderDescription(req, res, next) {
	const { item, tape_received } = req.query;

	const query = sql`
				SELECT
					vodf.order_description_uuid AS value,
					CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', vodf.tape_received) AS label,
					vodf.item_name,
					vodf.tape_received,
					vodf.tape_transferred,
					totals_of_oe.total_size,
					totals_of_oe.total_quantity,
					tcr.top,
					tcr.bottom,
					tape_coil.dyed_per_kg_meter
				FROM
					zipper.v_order_details_full vodf
				LEFT JOIN 
					(
						SELECT oe.order_description_uuid, SUM(oe.size::numeric * oe.quantity::numeric) as total_size, 
						SUM(oe.quantity::numeric) as total_quantity
						FROM zipper.order_entry oe 
				        group by oe.order_description_uuid
					) AS totals_of_oe ON totals_of_oe.order_description_uuid = vodf.order_description_uuid 
				LEFT JOIN zipper.tape_coil_required tcr ON vodf.item = tcr.item_uuid AND vodf.zipper_number = tcr.zipper_number_uuid AND vodf.end_type = tcr.end_type_uuid AND vodf.nylon_stopper = tcr.nylon_stopper_uuid
				LEFT JOIN zipper.tape_coil ON vodf.tape_coil_uuid = tape_coil.uuid
				WHERE 
					vodf.item_description != '---' AND vodf.item_description != '' AND tape_coil.dyed_per_kg_meter IS NOT NULL
				`;

	if (item == 'nylon') {
		query.append(
			sql` AND LOWER(vodf.item_name) = 'nylon plastic' AND LOWER(vodf.item_name) = 'nylon metallic'`
		);
	} else if (item == 'without-nylon') {
		query.append(
			sql` AND LOWER(vodf.item_name) != 'nylon plastic' AND LOWER(vodf.item_name) != 'nylon metallic'`
		);
	}

	if (tape_received == 'true') {
		query.append(sql` AND vodf.tape_received > 0`);
	}

	const orderEntryPromise = db.execute(query);

	try {
		const data = await orderEntryPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Description list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// export async function selectOrderDescriptionByItemNameAndZipperNumber(
// 	req,
// 	res,
// 	next
// ) {
// 	const { item_name, zipper_number } = req.params;

// 	console.log('params', req.params);
// 	console.log(item_name, zipper_number);

// 	const query = sql`SELECT
// 					vodf.order_description_uuid AS value,
// 					CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', vodf.tape_received) AS label

// 				FROM
// 					zipper.v_order_details_full vodf
// 				WHERE
// 					vodf.item_name = ${item_name} AND
// 					vodf.zipper_number_name = ${zipper_number}
// 				`;

// 	const orderEntryPromise = db.execute(query);

// 	try {
// 		const data = await orderEntryPromise;

// 		const toast = {
// 			status: 200,
// 			type: 'select_all',
// 			message: 'Order Description list',
// 		};

// 		res.status(200).json({ toast, data: data?.rows });
// 	} catch (error) {
// 		await handleError({ error, res });
// 	}
// }

export async function selectOrderDescriptionByCoilUuid(req, res, next) {
	const { coil_uuid } = req.params;

	const tapeCOilQuery = sql`
			SELECT
				item_uuid,
				zipper_number_uuid
			FROM
				zipper.tape_coil
			WHERE
				uuid = ${coil_uuid}
	`;

	try {
		const tapeCoilData = await db.execute(tapeCOilQuery);

		const item_uuid = tapeCoilData.rows[0].item_uuid;
		const zipper_number_uuid = tapeCoilData.rows[0].zipper_number_uuid;

		const query = sql`
			SELECT
				vodf.order_description_uuid AS value,
				CONCAT(vodf.order_number, ' ⇾ ', vodf.item_description, ' ⇾ ', vodf.tape_received) AS label,
				totals_of_oe.total_size,
				totals_of_oe.total_quantity,
				tcr.top,
				tcr.bottom,
				vodf.tape_received,
				vodf.tape_transferred
			FROM
				zipper.v_order_details_full vodf
			LEFT JOIN (
				SELECT oe.order_description_uuid, 
					SUM(oe.size::numeric * oe.quantity::numeric) as total_size, 
					SUM(oe.quantity::numeric) as total_quantity
				FROM zipper.order_entry oe
				GROUP BY oe.order_description_uuid
			) totals_of_oe ON vodf.order_description_uuid = totals_of_oe.order_description_uuid
			LEFT JOIN zipper.tape_coil_required tcr ON vodf.item = tcr.item_uuid AND vodf.zipper_number = tcr.zipper_number_uuid AND vodf.end_type = tcr.end_type_uuid
			LEFT JOIN 
				public.properties item_properties ON vodf.item = item_properties.uuid
			WHERE
				(vodf.tape_coil_uuid = ${coil_uuid} OR (vodf.item = ${item_uuid} AND vodf.zipper_number = ${zipper_number_uuid} AND vodf.tape_coil_uuid IS NULL)) AND vodf.order_description_uuid IS NOT NULL AND CASE WHEN lower(item_properties.name) = 'nylon' THEN vodf.nylon_stopper = tcr.nylon_stopper_uuid ELSE TRUE END
		`;

		const orderEntryPromise = db.execute(query);

		const data = await orderEntryPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Order Description list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectOrderNumberForPi(req, res, next) {
	const is_cash = req.query.is_cash === 'true';
	let query;

	if (is_cash) {
		query = sql`
	SELECT
		DISTINCT vod.order_info_uuid AS value,
		vod.order_number AS label
	FROM
		zipper.v_order_details vod
		LEFT JOIN zipper.order_info oi ON vod.order_info_uuid = oi.uuid
	WHERE
		vod.is_cash = 1 AND
		vod.marketing_uuid = ${req.params.marketing_uuid} AND
		oi.party_uuid = ${req.params.party_uuid}
	ORDER BY
		vod.order_number ASC
`;
	} else {
		query = sql`
	SELECT

		DISTINCT vod.order_info_uuid AS value,
		vod.order_number AS label
	FROM
		zipper.v_order_details vod
		LEFT JOIN zipper.order_info oi ON vod.order_info_uuid = oi.uuid
	WHERE
		vod.is_cash = 0 AND
		vod.marketing_uuid = ${req.params.marketing_uuid} AND
		oi.party_uuid = ${req.params.party_uuid}
	ORDER BY
		vod.order_number ASC
`;
	}

	const orderNumberPromise = db.execute(query);

	try {
		const data = await orderNumberPromise;

		const toast = {
			status: 200,
			type: 'select',
			message: 'Order Number of a marketing and party',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// purchase
export async function selectVendor(req, res, next) {
	const vendorPromise = db
		.select({
			value: purchaseSchema.vendor.uuid,
			label: purchaseSchema.vendor.name,
		})
		.from(purchaseSchema.vendor);

	try {
		const data = await vendorPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Vendor list',
		};

		res.status(200).json({ toast, data: data });
	} catch (error) {
		await handleError({ error, res });
	}
}

// material
export async function selectMaterialSection(req, res, next) {
	const sectionPromise = db
		.select({
			value: materialSchema.section.uuid,
			label: materialSchema.section.name,
		})
		.from(materialSchema.section);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Section list',
	};
	handleResponse({
		promise: sectionPromise,
		res,
		next,
		...toast,
	});
}

export async function selectMaterialType(req, res, next) {
	const typePromise = db
		.select({
			value: materialSchema.type.uuid,
			label: materialSchema.type.name,
		})
		.from(materialSchema.type);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Type list',
	};
	handleResponse({
		promise: typePromise,
		res,
		next,
		...toast,
	});
}

export async function selectMaterial(req, res, next) {
	const infoPromise = db
		.select({
			value: materialSchema.info.uuid,
			label: materialSchema.info.name,
			unit: materialSchema.info.unit,
			stock: materialSchema.stock.stock,
		})
		.from(materialSchema.info)
		.leftJoin(
			materialSchema.stock,
			eq(materialSchema.info.uuid, materialSchema.stock.material_uuid)
		);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Material list',
	};
	handleResponse({
		promise: infoPromise,
		res,
		next,
		...toast,
	});
}

// Commercial

export async function selectBank(req, res, next) {
	const bankPromise = db
		.select({
			value: commercialSchema.bank.uuid,
			label: commercialSchema.bank.name,
		})
		.from(commercialSchema.bank);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Bank list',
	};
	handleResponse({
		promise: bankPromise,
		res,
		next,
		...toast,
	});
}

export async function selectLCByPartyUuid(req, res, next) {
	const lcPromise = db
		.select({
			value: commercialSchema.lc.uuid,
			label: commercialSchema.lc.lc_number,
		})
		.from(commercialSchema.lc)
		.where(eq(commercialSchema.lc.party_uuid, req.params.party_uuid));

	const toast = {
		status: 200,
		type: 'select',
		message: 'LC list of a party',
	};
	handleResponse({
		promise: lcPromise,
		res,
		next,
		...toast,
	});
}

export async function selectPi(req, res, next) {
	const query = sql`
	SELECT
		pi_cash.uuid AS value,
		CONCAT('PI', TO_CHAR(pi_cash.created_at, 'YY'), '-', LPAD(pi_cash.id::text, 4, '0')) AS label,
		bank.name AS pi_bank,
		SUM(pi_cash_entry.pi_cash_quantity * zipper.order_entry.party_price) AS pi_value,
		ARRAY_AGG(DISTINCT v_order_details.order_number) AS order_numbers,
		v_order_details.marketing_name
	FROM
		commercial.pi_cash
	LEFT JOIN
		commercial.bank ON pi_cash.bank_uuid = bank.uuid
	LEFT JOIN
		commercial.pi_cash_entry ON pi_cash.uuid = pi_cash_entry.pi_cash_uuid
	LEFT JOIN
		zipper.sfg ON pi_cash_entry.sfg_uuid = sfg.uuid
	LEFT JOIN
		zipper.order_entry ON order_entry.uuid = sfg.order_entry_uuid
	LEFT JOIN
		zipper.v_order_details ON v_order_details.order_description_uuid = order_entry.order_description_uuid
	WHERE pi_cash.is_pi = 1 AND lc_uuid IS NULL
	GROUP BY
		pi_cash.uuid,
		bank.name,
		v_order_details.order_number,
		v_order_details.marketing_name;
	`;

	const piPromise = db.execute(query);

	try {
		const data = await piPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'PI list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}
// * HR * //
//* HR Department *//
export async function selectDepartment(req, res, next) {
	const departmentPromise = db
		.select({
			value: hrSchema.department.uuid,
			label: hrSchema.department.department,
		})
		.from(hrSchema.department);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Department list',
	};
	handleResponse({
		promise: departmentPromise,
		res,
		next,
		...toast,
	});
}
//* HR User *//
export async function selectHrUser(req, res, next) {
	const { designation } = req.query;

	const userPromise = db
		.select({
			value: hrSchema.users.uuid,
			label: hrSchema.users.name,
			designation: hrSchema.designation.designation,
		})
		.from(hrSchema.users)
		.leftJoin(
			hrSchema.designation,
			eq(hrSchema.users.designation_uuid, hrSchema.designation.uuid)
		)
		.where(
			designation
				? eq(sql`lower(designation.designation)`, designation)
				: null
		);

	try {
		const data = await userPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'User list',
		};

		res.status(200).json({ toast, data: data });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectDepartmentAndDesignation(req, res, next) {
	const DepartmentAndDesignation = db
		.select({
			value: hrSchema.designation.uuid,
			label: sql`concat(department.department, ' - ', designation.designation)`,
		})
		.from(hrSchema.designation)
		.leftJoin(
			hrSchema.department,
			eq(hrSchema.designation.department_uuid, hrSchema.department.uuid)
		);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Department and Designation list',
	};
	handleResponse({
		promise: DepartmentAndDesignation,
		res,
		next,
		...toast,
	});
}

// * Lab Dip * //
export async function selectLabDipRecipe(req, res, next) {
	const recipePromise = db
		.select({
			value: labDipSchema.recipe.uuid,
			label: sql`concat('LDR', to_char(recipe.created_at, 'YY'), '-', LPAD(recipe.id::text, 4, '0'), ' - ', recipe.name )`,
			approved: labDipSchema.recipe.approved,
			status: labDipSchema.recipe.status,
		})
		.from(labDipSchema.recipe);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Lab Dip Recipe list',
	};
	handleResponse({
		promise: recipePromise,
		res,
		next,
		...toast,
	});
}

export async function selectLabDipShadeRecipe(req, res, next) {
	const query = sql`
	SELECT
		recipe.uuid AS value,
		recipe.name AS label
	FROM
		lab_dip.recipe;`;

	const RecipePromise = db.execute(query);

	try {
		const data = await RecipePromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Recipe list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectLabDipInfo(req, res, next) {
	const InfoPromise = db
		.select({
			value: labDipSchema.info.uuid,
			label: sql`concat('LDI', to_char(info.created_at, 'YY'), '-', LPAD(info.id::text, 4, '0'))`,
		})
		.from(labDipSchema.info);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Info list',
	};

	handleResponse({
		promise: InfoPromise,
		res,
		next,
		...toast,
	});
}

// * Slider * //
export async function selectNameFromDieCastingStock(req, res, next) {
	const query = sql`
	SELECT
		die_casting.uuid AS value,
		concat(
			die_casting.name, ' --> ',
			itemProperties.short_name, ' - ',
			zipperProperties.short_name, ' - ',
			endTypeProperties.short_name, ' - ',
			pullerTypeProperties.short_name
		) AS label
	FROM
		slider.die_casting
	LEFT JOIN
		public.properties as itemProperties ON die_casting.item = itemProperties.uuid
	LEFT JOIN
		public.properties as zipperProperties ON die_casting.zipper_number = zipperProperties.uuid
	LEFT JOIN
		public.properties as endTypeProperties ON die_casting.end_type = endTypeProperties.uuid
	LEFT JOIN
		public.properties as pullerTypeProperties ON die_casting.puller_type = pullerTypeProperties.uuid;`;

	const namePromise = db.execute(query);

	try {
		const data = await namePromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Name list from Die Casting',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

export async function selectSliderStockWithOrderDescription(req, res, next) {
	const query = sql`
	SELECT
		stock.uuid AS value,
		concat(
			vodf.order_number, ' ⇾ ',
			vodf.item_description
		) AS label
	FROM
		slider.stock
	LEFT JOIN
		zipper.v_order_details_full vodf ON stock.order_description_uuid = vodf.order_description_uuid;
		`;

	const stockPromise = db.execute(query);

	try {
		const data = await stockPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Slider Stock list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// die casting using type

export async function selectDieCastingUsingType(req, res, next) {
	const { type } = req.params;

	const query = sql`
	SELECT
		die_casting.uuid AS value,
		die_casting.name AS label
	FROM
		slider.die_casting
	WHERE
		die_casting.type = ${type};`;

	const namePromise = db.execute(query);

	try {
		const data = await namePromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Name list from Die Casting',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// * Thread *//

// Count Length

export async function selectCountLength(req, res, next) {
	const query = sql`
	SELECT
		count_length.uuid AS value,
		concat(count_length.count, '/', count_length.length) AS label
	FROM
		thread.count_length;`;

	const countLengthPromise = db.execute(query);

	try {
		const data = await countLengthPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Count Length list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}

// Batch Id

export async function selectBatchId(req, res, next) {
	const batchIdPromise = db
		.select({
			value: threadSchema.batch.uuid,
			label: sql`concat('TB', to_char(batch.created_at, 'YY'), '-', LPAD(batch.id::text, 4, '0'))`,
		})
		.from(threadSchema.batch);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Batch Id list',
	};

	handleResponse({
		promise: batchIdPromise,
		res,
		next,
		...toast,
	});
}

// Dyes Category
export async function selectDyesCategory(req, res, next) {
	const dyesCategoryPromise = db
		.select({
			value: threadSchema.dyes_category.uuid,
			label: sql`concat(dyes_category.name, ' - ', dyes_category.id, ' - ', dyes_category.bleaching)`,
		})
		.from(threadSchema.dyes_category);

	const toast = {
		status: 200,
		type: 'select_all',
		message: 'Dyes Category list',
	};
	handleResponse({
		promise: dyesCategoryPromise,
		res,
		next,
		...toast,
	});
}

// * Delivery * //
// packing list
export async function selectPackingListByOrderInfoUuid(req, res, next) {
	const { order_info_uuid } = req.params;

	const { challan_uuid } = req.query;

	console.log(challan_uuid, 'challan_uuid');

	let query = sql`
	SELECT
		pl.uuid AS value,
		concat('PL', to_char(pl.created_at, 'YY'), '-', LPAD(pl.id::text, 4, '0')) AS label
	FROM
		delivery.packing_list pl
	WHERE
		pl.order_info_uuid = ${order_info_uuid} AND (pl.challan_uuid IS NULL`;

	// Conditionally add the challan_uuid part
	if (challan_uuid) {
		query += sql` OR pl.challan_uuid = ${challan_uuid}`;
	}
	query += sql`);`;

	const packingListPromise = db.execute(query);

	try {
		const data = await packingListPromise;

		const toast = {
			status: 200,
			type: 'select_all',
			message: 'Packing List list',
		};

		res.status(200).json({ toast, data: data?.rows });
	} catch (error) {
		await handleError({ error, res });
	}
}
