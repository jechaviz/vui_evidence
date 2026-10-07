module vui_evidence

fn test_comparison_subject_directive_maps_antigravity_visual_to_vexplorer_function() {
	directive := ui_clone_comparison_subject_directive(UiCloneSubjectInput{
		visual_reference_profile: 'antigravity'
		target_app_profile:       'veloexplorer'
		clone_intent:             'functional_ui_clone'
	})
	file_row := comparison_subject_row_for_component(directive.rows, 'file.list')

	assert directive.ready
	assert directive.cross_profile
	assert directive.visual_profile == 'antigravity'
	assert directive.functional_profile == 'vexplorer'
	assert directive.functional_source == 'target_app_profile'
	assert directive.functional_subject_explicit
	assert directive.equality_definition.contains('functional equality')
	assert directive.equality_definition.contains('supplies only geometry')
	assert directive.clone_target_policy.contains('not its runtime subject')
	assert directive.text_policy.contains('copied OCR labels never certify')
	assert directive.verification_order.any(it == 'mask_runtime_text_and_user_generated_content')
	assert directive.rejected_evidence_kinds.any(it == 'visual_clone_without_functional_subject')
	assert !directive.literal_text_can_certify
	assert !directive.visual_only_can_certify

	assert file_row.visual_component == 'prompt.composer'
	assert file_row.functional_component == 'file.list'
	assert file_row.equality_target.contains('file.list behavior')
	assert file_row.equality_target.contains('prompt.composer is only the visible locus')
	assert file_row.runtime_data_masks.any(it == 'file names')
	assert file_row.runtime_data_masks.any(it == 'prompt text')
	assert file_row.accepted_evidence_kinds.any(it == 'file_operation_receipt')
	assert file_row.rejected_evidence_kinds.any(it == 'ocr_text_match')
	assert file_row.required_behavior_probes.any(it == 'file.operations.mutate')
	assert !file_row.match_literal_text
	assert !file_row.compare_runtime_labels
	assert file_row.nonblind_reasoning
}

fn test_comparison_subject_directive_blocks_defaulted_functional_subject() {
	directive := ui_clone_comparison_subject_directive(UiCloneSubjectInput{
		target_profile: 'antigravity'
		clone_intent:   'functional_ui_clone'
	})

	assert !directive.ready
	assert !directive.functional_subject_explicit
	assert directive.blind_risk == 'functional_subject_defaulted_to_visual_reference'
	assert directive.blocker == 'functional_subject_defaulted_to_visual_reference'
	assert directive.equality_definition.contains('functional equality')
	assert directive.verification_order.any(it == 'resolve_explicit_functional_target_subject')
}

fn test_comparison_subject_directive_keeps_vvscode_editor_functional_not_literal() {
	directive := ui_clone_comparison_subject_directive(UiCloneSubjectInput{
		visual_reference_profile: 'vscode'
		target_app_profile:       'vvscode'
		clone_intent:             'functional_ui_clone'
	})
	editor_row := comparison_subject_row_for_component(directive.rows, 'editor.surface')

	assert directive.ready
	assert !directive.cross_profile
	assert directive.visual_profile == 'vscode'
	assert directive.functional_profile == 'vscode'
	assert directive.functional_subject == 'VS Code workbench contract'
	assert directive.clone_target_policy.contains('without freezing')
	assert editor_row.visual_component == 'editor.surface'
	assert editor_row.functional_component == 'editor.surface'
	assert editor_row.equality_target.contains('behavior, state, and stable anchors')
	assert editor_row.runtime_data_masks.any(it == 'document text')
	assert editor_row.required_behavior_probes.any(it == 'editor.surface.editing')
	assert !editor_row.match_literal_text
}

fn comparison_subject_row_for_component(rows []UiCloneComparisonSubjectDirectiveRow,
	component string) UiCloneComparisonSubjectDirectiveRow {
	clean := normalized_clone_value(component)
	for row in rows {
		if normalized_clone_value(row.functional_component) == clean {
			return row
		}
	}
	panic('missing comparison subject row for ${component}')
}
