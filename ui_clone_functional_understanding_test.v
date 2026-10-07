module vui_evidence

fn test_functional_understanding_asks_vexplorer_file_behavior_not_prompt_text() {
	row := ui_clone_functional_understanding('antigravity', 'vexplorer', 'functional_ui_clone').filter(it.functional_component == 'file.list')[0]

	assert row.visual_component == 'prompt.composer'
	assert row.functional_component == 'file.list'
	assert row.visual_locus_role.contains('supplies only the visible locus')
	assert row.functional_owner_role.contains('file.list owns commands')
	assert row.functional_question.contains('select, open, preview')
	assert row.expected_state_delta.contains('select open preview')
	assert row.runtime_data_masks.any(it == 'file names')
	assert row.runtime_data_masks.any(it == 'prompt text')
	assert row.accepted_evidence_kinds.any(it == 'state_delta')
	assert row.accepted_evidence_kinds.any(it == 'file_operation_receipt')
	assert row.rejected_evidence_kinds.any(it == 'ocr_text_match')
	assert row.rejected_evidence_kinds.any(it == 'copied_runtime_labels')
	assert row.nonblind_reasoning
	assert row.literal_text_is_runtime_data
	assert row.visual_only_rejected
	assert row.certification_rule.contains('visual mimicry do not count')
}

fn test_functional_understanding_summary_is_nonblind_for_cross_profile_clone() {
	summary := ui_clone_functional_understanding_summary('antigravity', 'vexplorer',
		'functional_ui_clone')

	assert summary.ready
	assert summary.cross_profile
	assert summary.visual_profile == 'antigravity'
	assert summary.functional_profile == 'vexplorer'
	assert summary.visual_subject == 'Antigravity desktop shell reference'
	assert summary.functional_subject == 'VExplorer desktop file-workbench contract'
	assert summary.row_count == 6
	assert summary.nonblind_row_count == 6
	assert summary.functional_question_count == 6
	assert summary.behavior_probe_count == 7
	assert summary.runtime_data_mask_count > 0
	assert !summary.literal_text_can_certify
	assert !summary.visual_only_can_certify
	assert summary.reasoning_rule.contains('functional question')
	assert summary.reasoning_rule.contains('state-delta')
}

fn test_functional_understanding_blocks_unknown_functional_profile() {
	summary := ui_clone_functional_understanding_summary('antigravity', 'unknown_shell',
		'functional_ui_clone')

	assert !summary.ready
	assert summary.blocker == 'functional_clone_target_profile_unknown'
	assert summary.row_count == 0
	assert summary.reasoning_rule == 'blocked: functional_clone_target_profile_unknown'
}

fn test_functional_understanding_direct_vscode_keeps_editor_behavior_question() {
	row := ui_clone_functional_understanding('vvscode_lowram', 'vscode', 'functional_ui_clone').filter(it.functional_component == 'editor.surface')[0]

	assert row.visual_component == 'editor.surface'
	assert row.functional_component == 'editor.surface'
	assert row.visual_locus_role.contains('for its own behavior')
	assert row.functional_question.contains('editing surface')
	assert row.runtime_data_masks.any(it == 'document text')
	assert row.accepted_evidence_kinds.any(it == 'probe:editor.surface.editing')
	assert row.nonblind_reasoning
}
