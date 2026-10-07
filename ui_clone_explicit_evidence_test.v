module vui_evidence

fn test_explicit_atomic_behavior_requires_real_functional_proof() {
	probe := ui_clone_behavior_probe_for_affordance('vexplorer', 'functional_ui_clone',
		'file.list.open_select') or { panic('missing file probe') }
	evidence := ui_clone_explicit_behavior_evidence_for_probe(probe, UiCloneExplicitBehaviorEvidence{
		id:             'file.open.probe'
		semantic_class: 'explicit_atomic_probe'
		state_delta:    'file_selection_open_preview_state_delta'
		source:         'waibav_atomic_probe'
	})

	assert evidence.found
	assert evidence.ok
	assert evidence.semantic_class == 'explicit_atomic_probe'
	assert evidence.semantic_reason.contains('state_delta')
}

fn test_explicit_atomic_behavior_rejects_ok_only_claims() {
	probe := ui_clone_behavior_probe_for_affordance('vexplorer', 'functional_ui_clone',
		'file.list.open_select') or { panic('missing file probe') }
	evidence := ui_clone_explicit_behavior_evidence_for_probe(probe, UiCloneExplicitBehaviorEvidence{
		id:             'file.open.name.only'
		affordance:     'file.list.open_select'
		component:      'file.list'
		semantic_class: 'explicit_atomic_probe'
		source:         'manual_manifest'
	})

	assert evidence.found
	assert !evidence.ok
	assert evidence.semantic_class == 'declared_affordance_without_behavior'
	assert evidence.semantic_reason.contains('no_command_action_state_delta_or_event')
}

fn test_explicit_atomic_behavior_rejects_screenshot_text_mimics() {
	probe := ui_clone_behavior_probe_for_affordance('antigravity', 'functional_ui_clone',
		'prompt.composer.compose') or { panic('missing prompt probe') }
	evidence := ui_clone_explicit_behavior_evidence_for_probe(probe, UiCloneExplicitBehaviorEvidence{
		id:             'prompt.ocr'
		affordance:     'prompt.composer.compose'
		component:      'prompt.composer'
		semantic_class: 'explicit_atomic_probe'
		state_delta:    'prompt_text_model_tool_local_submit_state_delta'
		source:         'segmented_screenshot_ocr'
		metadata:       {
			'literal_text': 'Ask anything, @ to mention, / for actions'
		}
	})

	assert evidence.found
	assert !evidence.ok
	assert evidence.semantic_class == 'visual_mimic'
	assert evidence.semantic_reason.contains('literal_text')
}
