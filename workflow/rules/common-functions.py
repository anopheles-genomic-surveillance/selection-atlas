# Common variables and functions for both workflows.

# Path to workflow config file.
config_file = workflow.configfiles[0]

# Contigs to be analysed.
contigs = config["contigs"]

# Analysis version identifier.
analysis_version = config["analysis_version"]

# Path to analysis results.
analysis_results_dir = f"results/{analysis_version}/analysis"

# Path to kernel set flag file.
kernel_set_file = "results/kernel.set"

# Path to main environment file.
environment_file = "workflow/envs/selection-atlas.yaml"
