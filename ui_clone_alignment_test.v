module vui_evidence

fn test_ui_clone_semantic_alignment_masks_antigravity_runtime_text() {
	rows := ui_clone_semantic_alignment('antigravity', 'functional_ui_clone')
	composer := ui_clone_semantic_alignment_for_component('antigravity', 'functional_ui_clone',
		'prompt.composer') or { panic('missing prompt composer alignment') }
	summary := ui_clone_semantic_alignment_summary('antigravity', 'functional_ui_clone')

	assert rows.len == 6
	assert composer.region == 'content_page'
	assert composer.pixel_policy == 'functional_layout'
	assert composer.dynamic_content
	assert !composer.compare_label
	assert composer.mask_runtime_data.any(it == 'prompt text')
	assert composer.behavior_probe_affordances.any(it == 'prompt.composer.compose')
	assert composer.certification_rule.contains('atomic behavior probe')
	assert composer.blind_clone_rejection.contains('OCR')
	assert summary.ready
	assert summary.row_count == 6
	assert summary.behavior_probe_count == 8
	assert !summary.literal_text_can_certify
	assert summary.certification_rule.contains('literal text is runtime data')
}

fn test_ui_clone_semantic_alignment_treats_vexplorer_file_rows_as_behavior_surface() {
	row := ui_clone_semantic_alignment_for_component('veloexplorer', 'functional_ui_clone',
		'file.list') or { panic('missing file list alignment') }

	assert row.region == 'content_page'
	assert row.parity_axis.contains('open_select_preview')
	assert row.mask_runtime_data.any(it == 'file names')
	assert row.required_behaviors.any(it.contains('select open preview'))
	assert row.behavior_probe_affordances == ['file.list.open_select', 'file.operations.mutate']
	assert row.background_safe_probe_count == 2
}

fn test_ui_clone_semantic_alignment_blocks_unknown_functional_profiles() {
	rows := ui_clone_semantic_alignment('mystery_shell', 'functional_ui_clone')
	summary := ui_clone_semantic_alignment_summary('mystery_shell', 'functional_ui_clone')

	assert rows.len == 0
	assert !summary.ready
	assert summary.blind_clone_blocker == 'functional_clone_target_profile_unknown'
	assert summary.certification_rule.contains('blocked')
	assert !summary.literal_text_can_certify
}
