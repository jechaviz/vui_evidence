module vui_evidence

fn test_functional_clone_plan_names_visual_and_functional_subjects() {
	plan := ui_clone_functional_clone_plan('antigravity', 'vexplorer', 'functional_ui_clone')

	assert plan.ready
	assert plan.cross_profile
	assert plan.visual_reference_subject == 'Antigravity desktop shell reference'
	assert plan.functional_target_subject == 'VExplorer desktop file-workbench contract'
	assert plan.clone_goal.contains('antigravity shape')
	assert plan.clone_goal.contains('vexplorer supplies behavior')
	assert plan.authority_rule.contains('visual profile owns geometry')
	assert plan.authority_rule.contains('functional profile owns actions')
	assert plan.visual_owned_components.any(it == 'prompt.composer')
	assert plan.functional_owned_components.any(it == 'file.list')
	assert plan.runtime_data_masks.any(it == 'file names')
	assert plan.runtime_data_masks.any(it == 'prompt text')
	assert plan.behavior_probe_affordances.any(it == 'file.operations.mutate')
	assert plan.rejected_evidence_kinds.any(it == 'copied_runtime_labels')
	assert plan.rejected_evidence_kinds.any(it == 'visual_clone_without_functional_subject')
	assert !plan.literal_text_can_certify
	assert !plan.visual_only_can_certify
	assert plan.certification_gate.contains('explicit visual subject')
	assert plan.certification_gate.contains('explicit functional subject')
}

fn test_functional_clone_plan_blocks_unknown_functional_subject() {
	plan := ui_clone_functional_clone_plan('antigravity', 'unknown_shell', 'functional_ui_clone')

	assert !plan.ready
	assert plan.blocker == 'functional_clone_target_profile_unknown'
	assert plan.functional_target_subject == 'unknown UI product contract'
	assert plan.certification_gate == 'blocked: functional_clone_target_profile_unknown'
	assert plan.behavior_probe_affordances.len == 0
}

fn test_functional_clone_plan_direct_vscode_keeps_subject_but_masks_runtime_text() {
	plan := ui_clone_functional_clone_plan('vvscode_lowram', 'vscode', 'functional_ui_clone')

	assert plan.ready
	assert !plan.cross_profile
	assert plan.visual_profile == 'vscode'
	assert plan.functional_profile == 'vscode'
	assert plan.visual_reference_subject == 'VS Code workbench contract'
	assert plan.functional_target_subject == 'VS Code workbench contract'
	assert plan.clone_goal.contains('without copying runtime text')
	assert plan.runtime_data_masks.any(it == 'document text')
	assert plan.behavior_probe_affordances.any(it == 'editor.surface.editing')
}
