module vui_evidence

fn test_functional_clone_evidence_ledger_maps_antigravity_locus_to_vexplorer_behavior() {
	ledger := ui_clone_functional_clone_evidence_ledger(UiCloneSubjectInput{
		visual_reference_profile: 'antigravity'
		target_app_profile:       'veloexplorer'
		clone_intent:             'functional_ui_clone'
	}, vexplorer_functional_clone_signals())
	file_row := functional_clone_evidence_row_for_component(ledger.rows, 'file.list')

	assert ledger.ready
	assert ledger.functional_parity_candidate
	assert ledger.visual_profile == 'antigravity'
	assert ledger.functional_profile == 'vexplorer'
	assert ledger.cross_profile
	assert ledger.behavior_probe_passed_count == 7
	assert ledger.behavior_probe_missing_count == 0
	assert ledger.functional_certified_row_count == ledger.rows.len
	assert !ledger.literal_text_can_certify
	assert !ledger.visual_only_can_certify

	assert file_row.visual_component == 'prompt.composer'
	assert file_row.functional_component == 'file.list'
	assert file_row.equality_target.contains('file.list behavior')
	assert file_row.visual_locus_rule.contains('locates the surface')
	assert file_row.functional_question.contains('select, open, preview')
	assert file_row.runtime_data_policy.contains('file names')
	assert !file_row.compare_literal_text
	assert file_row.certification_status == 'certified'
	assert file_row.functional_certified
	assert file_row.matched_signal_ids.any(it == 'file.open')
	assert file_row.matched_signal_ids.any(it == 'file.rename')
}

fn test_functional_clone_evidence_ledger_rejects_prompt_text_as_file_behavior() {
	ledger := ui_clone_functional_clone_evidence_ledger(UiCloneSubjectInput{
		visual_reference_profile: 'antigravity'
		target_app_profile:       'veloexplorer'
		clone_intent:             'functional_ui_clone'
	}, [
		UiCloneRuntimeSignal{
			id:         'prompt.ocr'
			affordance: 'file.list.open_select'
			component:  'prompt.composer'
			source:     'segmented_screenshot_ocr'
			metadata:   {
				'literal_text': 'Ask anything'
				'visual_only':  'true'
			}
		},
	])
	file_row := functional_clone_evidence_row_for_component(ledger.rows, 'file.list')

	assert !ledger.ready
	assert !ledger.functional_parity_candidate
	assert ledger.blocker == 'functional_clone_evidence_contains_visual_mimic'
	assert ledger.visual_only_blocked_count == 1
	assert ledger.behavior_probe_failed_count == 1
	assert file_row.visual_only_blocked
	assert file_row.certification_status == 'visual_only_rejected'
	assert file_row.evidence_classes.any(it == 'visual_mimic')
	assert file_row.certification_rule.contains('screenshot/OCR similarity cannot answer file.list')
}

fn test_functional_clone_evidence_ledger_blocks_blind_visual_default() {
	ledger := ui_clone_functional_clone_evidence_ledger(UiCloneSubjectInput{
		target_profile: 'antigravity'
		clone_intent:   'functional_ui_clone'
	}, []UiCloneRuntimeSignal{})

	assert !ledger.ready
	assert !ledger.functional_parity_candidate
	assert !ledger.functional_subject_explicit
	assert ledger.blind_risk == 'functional_subject_defaulted_to_visual_reference'
	assert ledger.blocker == 'functional_subject_defaulted_to_visual_reference'
	assert ledger.certification_rule.contains('blocked')
}

fn vexplorer_functional_clone_signals() []UiCloneRuntimeSignal {
	return [
		UiCloneRuntimeSignal{
			id:          'frame.resize'
			state_delta: 'window_bounds_and_state_change_with_native_controls'
			source:      'appdrive.window'
		},
		UiCloneRuntimeSignal{
			id:         'path.open'
			command_id: 'vexplorer.openWorkspaceRoot'
			metadata:   {
				'workspace_root': 'C:/git/v_projects/vexplorer'
			}
			source:     'vexplorer_runtime'
		},
		UiCloneRuntimeSignal{
			id:          'view.search'
			state_delta: 'active_view_id changes workspace panel updates'
			metadata:    {
				'active_view_id': 'search'
			}
			source:      'vexplorer_runtime'
		},
		UiCloneRuntimeSignal{
			id:          'tree.rename'
			state_delta: 'folder_tree_selection context_menu rename'
			metadata:    {
				'selection': 'src'
			}
			source:      'vexplorer_runtime'
		},
		UiCloneRuntimeSignal{
			id:         'file.open'
			command_id: 'vexplorer.file.open'
			metadata:   {
				'opened_file': 'src/main.v'
			}
			source:     'vexplorer_runtime'
		},
		UiCloneRuntimeSignal{
			id:         'file.rename'
			command_id: 'fs.rename'
			metadata:   {
				'file_operation': 'rename'
			}
			source:     'vexplorer_runtime'
		},
		UiCloneRuntimeSignal{
			id:          'status.update'
			state_delta: 'status_slots_update_from_workspace_file_events'
			metadata:    {
				'live_kind': 'selection_path_operation'
			}
			source:      'vexplorer_runtime'
		},
	]
}

fn functional_clone_evidence_row_for_component(rows []UiCloneFunctionalCloneEvidenceRow,
	component string) UiCloneFunctionalCloneEvidenceRow {
	for row in rows {
		if row.functional_component == component {
			return row
		}
	}
	panic('missing functional clone evidence row for ${component}')
}
