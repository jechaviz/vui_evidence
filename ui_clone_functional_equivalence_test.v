module vui_evidence

fn test_functional_equivalence_maps_antigravity_visual_to_vexplorer_behavior() {
	row := ui_clone_functional_equivalence_for_component('antigravity', 'vexplorer',
		'functional_ui_clone', 'file.list') or { panic('missing file.list equivalence') }

	assert row.cross_profile
	assert row.visual_profile == 'antigravity'
	assert row.functional_profile == 'vexplorer'
	assert row.visual_component == 'prompt.composer'
	assert row.functional_component == 'file.list'
	assert row.substitution_kind == 'semantic_cross_profile_substitution'
	assert row.equivalence_role.contains('behavior ownership')
	assert !row.literal_text_can_certify
	assert !row.visual_only_can_certify
	assert row.functional_runtime_masks.any(it == 'file names')
	assert row.functional_runtime_masks.any(it == 'prompt text')
	assert row.behavior_probe_affordances.any(it == 'file.list.open_select')
	assert row.behavior_probe_affordances.any(it == 'file.operations.mutate')
	assert row.certification_gate.contains('functional behavior probe')
}

fn test_functional_equivalence_summary_requires_nonblind_behavior() {
	summary := ui_clone_functional_equivalence_summary('antigravity', 'vexplorer',
		'functional_ui_clone')

	assert summary.ready
	assert summary.cross_profile
	assert summary.visual_profile == 'antigravity'
	assert summary.functional_profile == 'vexplorer'
	assert summary.mapped_surface_count == 6
	assert summary.unmapped_functional_surface_count == 0
	assert summary.behavior_probe_count == 7
	assert summary.runtime_data_mask_count > 0
	assert !summary.literal_text_can_certify
	assert !summary.visual_only_can_certify
	assert summary.certification_rule.contains('atomic behavior receipts')
}

fn test_functional_equivalence_blocks_unknown_functional_profile() {
	summary := ui_clone_functional_equivalence_summary('antigravity', 'mystery_shell',
		'functional_ui_clone')

	assert !summary.ready
	assert summary.rows.len == 0
	assert summary.blocker == 'functional_clone_target_profile_unknown'
	assert summary.certification_rule.contains('blocked')
}

fn test_functional_equivalence_direct_profile_keeps_component_identity() {
	row := ui_clone_functional_equivalence_for_component('vvscode_lowram', 'vscode',
		'functional_ui_clone', 'editor.surface') or { panic('missing editor.surface equivalence') }

	assert !row.cross_profile
	assert row.visual_profile == 'vscode'
	assert row.functional_profile == 'vscode'
	assert row.visual_component == 'editor.surface'
	assert row.functional_component == 'editor.surface'
	assert row.substitution_kind == 'direct_profile_surface'
	assert row.functional_runtime_masks.any(it == 'document text')
	assert row.behavior_probe_affordances.any(it == 'editor.surface.editing')
}
