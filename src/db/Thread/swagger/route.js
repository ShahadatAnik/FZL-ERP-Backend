// * Thread Machine * //
import SE, { SED } from '../../../util/swagger_example.js';

export const pathThreadMachine = {
	'/thread/machine': {
		get: {
			tags: ['thread.machine'],
			summary: 'Get all Thread Machine',
			description: 'Get all Thread Machine',
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/machine',
								},
							},
						},
					},
				},
			},
		},

		post: {
			tags: ['thread.machine'],
			summary: 'Create Thread Machine',
			description: 'Create Thread Machine',
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/machine',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/machine',
							},
						},
					},
				},
			},
		},
	},
	'/thread/machine/{uuid}': {
		get: {
			tags: ['thread.machine'],
			summary: 'Get Thread Machine',
			description: 'Get Thread Machine',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/machine',
							},
						},
					},
				},
			},
		},
		put: {
			tags: ['thread.machine'],
			summary: 'Update Thread Machine',
			description: 'Update Thread Machine',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/machine',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/machine',
							},
						},
					},
				},
			},
		},
		delete: {
			tags: ['thread.machine'],
			summary: 'Delete Thread Machine',
			description: 'Delete Thread Machine',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/machine',
							},
						},
					},
				},
			},
		},
	},
};

// * Thread Count Length * //

export const pathThreadCountLength = {
	'/thread/count-length': {
		get: {
			tags: ['thread.count_length'],
			summary: 'Get all Thread Count Length',
			description: 'Get all Thread Count Length',
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/count_length',
								},
							},
						},
					},
				},
			},
		},

		post: {
			tags: ['thread.count_length'],
			summary: 'Create Thread Count Length',
			description: 'Create Thread Count Length',
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/count_length',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/count_length',
							},
						},
					},
				},
				400: SE.response(400),
				404: SE.response(404),
				405: SE.response(405),
			},
		},
	},
	'/thread/count-length/{uuid}': {
		get: {
			tags: ['thread.count_length'],
			summary: 'Get Thread Count Length',
			description: 'Get Thread Count Length',
			parameters: [SE.parameter_uuid('uuid', 'uuid')],
			responses: {
				200: SE.response_schema(200, {
					uuid: SE.uuid(),
					count: SE.string(),
					length: SE.string(),
					created_at: SE.date_time(),
					updated_at: SE.date_time(),
				}),
				400: SE.response(400),
				404: SE.response(404),
				405: SE.response(405),
			},
		},
		put: {
			tags: ['thread.count_length'],
			summary: 'Update Thread Count Length',
			description: 'Update Thread Count Length',
			parameters: [SE.parameter_uuid('uuid', 'uuid')],
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/count_length',
						},
					},
				},
			},
			responses: {
				201: SE.response_schema_ref(201, 'thread/count_length'),
				400: SE.response(400),
				404: SE.response(404),
				405: SE.response(405),
			},
		},

		delete: {
			tags: ['thread.count_length'],
			summary: 'Delete Thread Count Length',
			description: 'Delete Thread Count Length',
			parameters: [SE.parameter_uuid('uuid', 'uuid')],
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/count_length',
							},
						},
					},
				},
			},
		},
	},
};

// * Thread Order Info * //

export const pathThreadOrderInfo = {
	'/thread/order-info': {
		get: {
			tags: ['thread.order_info'],
			summary: 'Get all Thread Order Info',
			description: 'Get all Thread Order Info',
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/order_info',
								},
							},
						},
					},
				},
			},
		},

		post: {
			tags: ['thread.order_info'],
			summary: 'Create Thread Order Info',
			description: 'Create Thread Order Info',
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/order_info',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_info',
							},
						},
					},
				},
			},
		},
	},
	'/thread/order-info/{uuid}': {
		get: {
			tags: ['thread.order_info'],
			summary: 'Get Thread Order Info',
			description: 'Get Thread Order Info',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_info',
							},
						},
					},
				},
			},
		},
		put: {
			tags: ['thread.order_info'],
			summary: 'Update Thread Order Info',
			description: 'Update Thread Order Info',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/order_info',
						},
					},
				},
			},

			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_info',
							},
						},
					},
				},
			},
		},

		delete: {
			tags: ['thread.order_info'],
			summary: 'Delete Thread Order Info',
			description: 'Delete Thread Order Info',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_info',
							},
						},
					},
				},
			},
		},
	},
	'/thread/order-info-details/by/{order_info_uuid}': {
		get: {
			tags: ['thread.order_info'],
			summary: 'Get Thread Order Info Details by Order Info UUID',
			description: 'Get Thread Order Info Details by Order Info UUID',
			parameters: [
				SE.parameter_uuid('order_info_uuid', 'order_info_uuid'),
			],
			responses: {
				200: SE.response_schema(200, {
					uuid: SE.uuid(),
					party_uuid: SE.uuid(),
					party_name: SE.string(),
					marketing_uuid: SE.uuid(),
					marketing_name: SE.string('John Doe'),
					factory_uuid: SE.uuid(),
					factory_name: SE.string('John Doe'),
					merchandiser_uuid: SE.uuid(),
					merchandiser_name: SE.string('John Doe'),
					buyer_uuid: SE.uuid(),
					buyer_name: SE.string('John Doe'),
					created_by: SE.uuid(),
					created_by_name: SE.string('John Doe'),
					created_at: SE.date_time(),
					updated_at: SE.date_time(),
					remarks: SE.string(),
					order_entry: {
						uuid: SE.uuid(),
						order_info_uuid: SE.uuid(),
						lab_reference: SE.string(),
						color: SE.string(),
						shade_recipe_uuid: SE.uuid(),
						shade_recipe_name: SE.string(),
						po: SE.string(),
						style: SE.string(),
						count_length_uuid: SE.uuid(),
						count: SE.string(),
						length: SE.string(),
						count_length_name: SE.string(),
						quantity: SE.integer(),
						company_price: SE.number(),
						party_price: SE.number(),
						swatch_approval_date: SE.date_time(),
						production_quantity: SE.integer(),
						created_by: SE.uuid(),
						created_by_name: SE.string('John Doe'),
						created_at: SE.date_time(),
						updated_at: SE.date_time(),
					},
				}),
			},
		},
	},
	'/thread/order-swatch': {
		get: {
			tags: ['thread.order_info'],
			summary: 'Get Thread Order Swatch',
			description: 'Get Thread Order Swatch',
			responses: {
				200: SE.response_schema(200, {
					uuid: SE.uuid(),
					id: SE.integer(),
					order_number: SE.string(),
					style: SE.string(),
					color: SE.string(),
					shade_recipe_uuid: SE.uuid(),
					shade_recipe_name: SE.string(),
					po: SE.string(),
					count_length_uuid: SE.uuid(),
					count: SE.integer(),
					length: SE.integer(),
					count_length_name: SE.string(),
					order_quantity: SE.integer(),
					created_at: SE.date_time(),
					updated_at: SE.date_time(),
					remarks: SE.string(),
				}),
			},
		},
	},
};

// * Thread Order Entry * //

export const pathThreadOrderEntry = {
	'/thread/order-entry': {
		get: {
			tags: ['thread.order_entry'],
			summary: 'Get all Thread Order Entry',
			description: 'Get all Thread Order Entry',
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/order_entry',
								},
							},
						},
					},
				},
			},
		},
		post: {
			tags: ['thread.order_entry'],
			summary: 'Create Thread Order Entry',
			description: 'Create Thread Order Entry',
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/order_entry',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_entry',
							},
						},
					},
				},
			},
		},
	},
	'/thread/order-entry/{uuid}': {
		get: {
			tags: ['thread.order_entry'],
			summary: 'Get Thread Order Entry',
			description: 'Get Thread Order Entry',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_entry',
							},
						},
					},
				},
			},
		},
		put: {
			tags: ['thread.order_entry'],
			summary: 'Update Thread Order Entry',
			description: 'Update Thread Order Entry',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/order_entry',
						},
					},
				},
			},

			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_entry',
							},
						},
					},
				},
			},
		},

		delete: {
			tags: ['thread.order_entry'],
			summary: 'Delete Thread Order Entry',
			description: 'Delete Thread Order Entry',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/order_entry',
							},
						},
					},
				},
			},
		},
	},
	'/thread/order-entry/by/{order_info_uuid}': {
		get: {
			tags: ['thread.order_entry'],
			summary: 'Get Thread Order Entry by Order Info UUID',
			description: 'Get Thread Order Entry by Order Info UUID',
			parameters: [
				SE.parameter_uuid('order_info_uuid', 'order_info_uuid'),
			],
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/order_entry',
								},
							},
						},
					},
				},
			},
		},
	},
};

// * Thread Batch Entry * //

export const pathThreadBatchEntry = {
	'/thread/batch-entry': {
		get: {
			tags: ['thread.batch_entry'],
			summary: 'Get all Thread Batch Entry',
			description: 'Get all Thread Batch Entry',
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/batch_entry',
								},
							},
						},
					},
				},
			},
		},

		post: {
			tags: ['thread.batch_entry'],
			summary: 'Create Thread Batch Entry',
			description: 'Create Thread Batch Entry',
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/batch_entry',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch_entry',
							},
						},
					},
				},
			},
		},
	},
	'/thread/batch-entry/{uuid}': {
		get: {
			tags: ['thread.batch_entry'],
			summary: 'Get Thread Batch Entry',
			description: 'Get Thread Batch Entry',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch_entry',
							},
						},
					},
				},
			},
		},
		put: {
			tags: ['thread.batch_entry'],
			summary: 'Update Thread Batch Entry',
			description: 'Update Thread Batch Entry',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/batch_entry',
						},
					},
				},
			},

			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch_entry',
							},
						},
					},
				},
			},
		},

		delete: {
			tags: ['thread.batch_entry'],
			summary: 'Delete Thread Batch Entry',
			description: 'Delete Thread Batch Entry',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch_entry',
							},
						},
					},
				},
			},
		},
	},
};

// * Thread Batch * //

export const pathThreadBatch = {
	'/thread/batch': {
		get: {
			tags: ['thread.batch'],
			summary: 'Get all Thread Batch',
			description: 'Get all Thread Batch',
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								type: 'array',
								items: {
									$ref: '#/definitions/thread/batch',
								},
							},
						},
					},
				},
			},
		},

		post: {
			tags: ['thread.batch'],
			summary: 'Create Thread Batch',
			description: 'Create Thread Batch',
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/batch',
						},
					},
				},
			},
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch',
							},
						},
					},
				},
			},
		},
	},
	'/thread/batch/{uuid}': {
		get: {
			tags: ['thread.batch'],
			summary: 'Get Thread Batch',
			description: 'Get Thread Batch',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				200: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch',
							},
						},
					},
				},
			},
		},
		put: {
			tags: ['thread.batch'],
			summary: 'Update Thread Batch',
			description: 'Update Thread Batch',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			requestBody: {
				content: {
					'application/json': {
						schema: {
							$ref: '#/definitions/thread/batch',
						},
					},
				},
			},

			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch',
							},
						},
					},
				},
			},
		},

		delete: {
			tags: ['thread.batch'],
			summary: 'Delete Thread Batch',
			description: 'Delete Thread Batch',
			parameters: [
				{
					name: 'uuid',
					in: 'path',
					required: true,
					schema: {
						type: 'string',
						format: 'uuid',
					},
				},
			],
			responses: {
				201: {
					description: 'Success',
					content: {
						'application/json': {
							schema: {
								$ref: '#/definitions/thread/batch',
							},
						},
					},
				},
			},
		},
	},
};

// * Thread * //

export const pathThread = {
	...pathThreadMachine,
	...pathThreadCountLength,
	...pathThreadOrderInfo,
	...pathThreadOrderEntry,
	...pathThreadBatchEntry,
	...pathThreadBatch,
};
