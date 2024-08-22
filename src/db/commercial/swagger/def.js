//* ./schema.js#bank

export const defCommercialBank = {
	type: 'object',
	required: ['uuid', 'name', 'swift_code', 'created_at'],
	properties: {
		uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		name: {
			type: 'string',
			example: 'Bangladesh Name',
		},
		swift_code: {
			type: 'string',
			example: 'BNGD',
		},
		address: {
			type: 'string',
			example: 'Dhaka, Bangladesh',
		},
		policy: {
			type: 'string',
			example: 'policy_name',
		},
		created_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		updated_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		remarks: {
			type: 'string',
			example: 'Remarks',
		},
	},
	xml: {
		name: 'Commercial/Bank',
	},
};

export const defCommercialLc = {
	type: 'object',
	required: [
		'uuid',
		'party_uuid',
		'file_no',
		'lc_number',
		'lc_date',
		'ldbc_fdbc',
		'commercial_executive',
		'party_bank',
		'expiry_date',
		'at_sight',
		'created_at',
		'created_by',
	],
	properties: {
		uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		party_uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		file_no: {
			type: 'string',
			example: '1234/2024',
		},
		lc_number: {
			type: 'string',
			example: '1234/2024',
		},
		lc_date: {
			type: 'string',
			example: '2024-01-01 00:00:00',
		},
		payment_value: {
			type: 'number',
			example: 1000.0,
		},
		payment_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		ldbc_fdbc: {
			type: 'string',
			example: 'LDBC',
		},
		acceptance_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		maturity_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		commercial_executive: {
			type: 'string',
			example: 'John Doe',
		},
		party_bank: {
			type: 'string',
			example: 'Bangladesh Bank',
		},
		production_complete: {
			type: 'integer',
			example: 0,
		},
		lc_cancel: {
			type: 'integer',
			example: 0,
		},
		handover_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		shipment_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		expiry_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		ud_no: {
			type: 'string',
			example: '1234/2024',
		},
		ud_received: {
			type: 'string',
			example: '2024-01-01 00:00:00',
		},
		at_sight: {
			type: 'string',
			example: 'At Sight',
		},
		amd_date: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		amd_count: {
			type: 'integer',
			example: 0,
		},
		problematical: {
			type: 'integer',
			example: 0,
		},
		epz: {
			type: 'integer',
			example: 0,
		},
		created_by: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		created_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		updated_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		remarks: {
			type: 'string',
			example: 'Remarks',
		},
	},
	xml: {
		name: 'Commercial/Lc',
	},
};

export const defCommercialPi = {
	type: 'object',
	required: [
		'uuid',
		'lc_uuid',
		'order_info_ids',
		'marketing_uuid',
		'party_uuid',
		'merchandiser_uuid',
		'factory_uuid',
		'bank_uuid',
		'validity',
		'payment',
		'created_by',
		'created_at',
	],
	properties: {
		uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		id: {
			type: 'integer',
			example: 1,
		},
		lc_uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		order_info_uuids: {
			type: 'array',
			items: {
				type: 'string',
			},
			example: '[{"J3Au9M73Zb9saxj"}]',
		},
		marketing_uuid: {
			type: 'string',
			example: 'j14NcevenyrWSei',
		},
		party_uuid: {
			type: 'string',
			example: 'cf-daf86b3eedf1',
		},
		merchandiser_uuid: {
			type: 'string',
			example: 'LDedGLTqSAipBf1',
		},
		factory_uuid: {
			type: 'string',
			example: 'cf-daf86b3eedf1',
		},
		bank_uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		validity: {
			type: 'integer',
			example: 0,
		},
		payment: {
			type: 'integer',
			example: 0,
		},
		created_by: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		created_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		updated_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		remarks: {
			type: 'string',
			example: 'Remarks',
		},
	},
	xml: {
		name: 'Commercial/Pi',
	},
};

export const defCommercialPiEntry = {
	type: 'object',
	required: ['uuid', 'pi_uuid', 'sfg_uuid', 'pi_quantity', 'created_at'],
	properties: {
		uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		pi_uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		sfg_uuid: {
			type: 'string',
			example: 'igD0v9DIJQhJeet',
		},
		pi_quantity: {
			type: 'number',
			example: 1000.0,
		},
		created_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		updated_at: {
			type: 'string',
			format: 'date-time',
			example: '2024-01-01 00:00:00',
		},
		remarks: {
			type: 'string',
			example: 'Remarks',
		},
	},
	xml: {
		name: 'Commercial/PiEntry',
	},
};

// * Marge All
export const defCommercial = {
	bank: defCommercialBank,
	lc: defCommercialLc,
	pi: defCommercialPi,
	pi_entry: defCommercialPiEntry,
};

// * Tag
export const tagCommercial = [
	{
		name: 'commercial.bank',
		description: 'Everything about commercial bank',
		externalDocs: {
			description: 'Find out more',
			url: 'http://swagger.io',
		},
	},
	{
		name: 'commercial.lc',
		description: 'Operations about commercial lc',
		externalDocs: {
			description: 'Find out more',
			url: 'http://swagger.io',
		},
	},
	{
		name: 'commercial.pi',
		description: 'Operations about commercial pi',
		externalDocs: {
			description: 'Find out more',
			url: 'http://swagger.io',
		},
	},
	{
		name: 'commercial.pi_entry',
		description: 'Operations about commercial pi_entry',
		externalDocs: {
			description: 'Find out more',
			url: 'http://swagger.io',
		},
	},
];