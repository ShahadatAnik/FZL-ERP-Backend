import { desc, eq, sql } from 'drizzle-orm';
import {
	handleError,
	handleResponse,
	validateRequest,
} from '../../../util/index.js';
import db from '../../index.js';

export async function selectGoodsInWarehouse(req, res, next) {
	if (!(await validateRequest(req, next))) return;

	const query = sql`
		    WITH challan_data AS (
        SELECT
            sum(sfg.warehouse)::float8 as amount,
            count(*) as number_of_challan,
            null as sewing_thread,
            CASE 
                WHEN vodf.nylon_stopper_name = 'Metallic' THEN vodf.item_name || ' Metallic'
                WHEN vodf.nylon_stopper_name = 'Plastic' THEN vodf.item_name || ' Plastic'
                ELSE vodf.item_name
            END as item_name
        FROM
            delivery.packing_list pl
            LEFT JOIN delivery.packing_list_entry ple ON pl.uuid = ple.packing_list_uuid
            LEFT JOIN zipper.v_order_details_full vodf ON pl.order_info_uuid = vodf.order_info_uuid
            LEFT JOIN zipper.sfg sfg ON ple.sfg_uuid = sfg.uuid
        WHERE pl.challan_uuid IS NULL
        GROUP BY
            item_name, sewing_thread, vodf.nylon_stopper_name, vodf.item_name
        UNION
        SELECT
            sum(toe.warehouse)::float8  as amount,
            sum(toe.carton_quantity) as number_of_carton,
            'Sewing Thread' as sewing_thread,
            null as item_name
        FROM
            thread.order_entry toe
            LEFT JOIN thread.order_info toi ON toe.order_info_uuid = toi.uuid
    )
    SELECT
        *,
        (SELECT SUM(number_of_challan) FROM challan_data) as total_number_of_challan
    FROM challan_data;
	`;
	const resultPromise = db.execute(query);

	try {
		const data = await resultPromise;
		const toast = {
			status: 200,
			type: 'select',
			message: 'Goods in Warehouse',
		};

		return res.status(200).json({ toast, data: data.rows });
	} catch (error) {
		handleError({ error, res });
	}
}