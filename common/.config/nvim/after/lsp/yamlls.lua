return {
	settings = {
		yaml = {
			validate = true,
			hover = true,
			completion = true,
			schemas = {
				kubernetes = {
					"*.yaml",
					"*.yml",
				},
			},
		},
	},
}
