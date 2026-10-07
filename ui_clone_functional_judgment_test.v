module vui_evidence

fn test_functional_judgment_allows_nonblind_vexplorer_functionality() {
	judgment := ui_clone_functional_judgment(UiCloneSubjectInput{
		visual_reference_profile: 'antigravity'
		target_app_profile:       'veloexplorer'
		clone_intent:             'functional_ui_clone'
	}, judgment_vexplorer_runtime_signals())
	file_row := judgment_row_for_component(judgment.rows, 'file.list')

	assert judgment.ready
	assert judgment.clone_claim_allowed
	assert judgment.functional_coverage_percent == 100
	assert judgment.certified_row_count == judgment.row_count
	assert judgment.understood_row_count == judgment.row_count
	assert judgment.behavior_evidence_required == judgment.behavior_evidence_passed
	assert judgment.behavior_evidence_missing == 0
	assert judgment.behavior_evidence_failed == 0
	assert !judgment.literal_text_can_certify
	assert !judgment.visual_only_can_certify
	assert judgment.decision_rule.contains('functional clone allowed')

	assert file_row.visual_component == 'prompt.composer'
	assert file_row.functional_component == 'file.list'
	assert file_row.visual_anchor_subject.contains('prompt.composer stable geometry')
	assert file_row.equalized_subject.contains('file.list behavior and state deltas')
	assert file_row.excluded_literal_subject.contains('runtime labels')
	assert file_row.clone_reasoning_mode == 'functional_behavior_over_literal_screen_text'
	assert file_row.visual_role == 'stable_visual_locus_for_file.list'
	assert file_row.functional_role == 'behavior_owner_mapped_to_prompt.composer_locus'
	assert file_row.atomic_parity_contract.contains('prompt.composer locates file.list')
	assert file_row.atomic_parity_contract.contains('file.list.open_select')
	assert file_row.runtime_evidence_contract.contains('accepted evidence')
	assert file_row.literal_copy_blocker.contains('static screenshots cannot certify file.list')
	assert file_row.verdict == 'functionally_equivalent'
	assert file_row.function_understood
	assert file_row.visual_locus_understood
	assert file_row.dynamic_text_masked
	assert file_row.coverage_percent == 100
	assert !file_row.compare_literal_text
	assert file_row.text_policy.contains('runtime text is data')
	assert file_row.decision_reason.contains('accepted runtime evidence')
	assert file_row.next_required_evidence.len == 0
}

fn test_functional_judgment_rejects_visual_mimic_as_functionality() {
	judgment := ui_clone_functional_judgment(UiCloneSubjectInput{
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
	file_row := judgment_row_for_component(judgment.rows, 'file.list')

	assert !judgment.ready
	assert !judgment.clone_claim_allowed
	assert judgment.blocker == 'functional_clone_evidence_contains_visual_mimic'
	assert judgment.functional_coverage_percent < 100
	assert judgment.visual_only_rejected_row_count == 1
	assert judgment.failed_row_count == 1
	assert judgment.behavior_evidence_failed == 1
	assert !judgment.literal_text_can_certify
	assert !judgment.visual_only_can_certify

	assert file_row.verdict == 'visual_only_rejected'
	assert file_row.equalized_subject.contains('file.list behavior')
	assert file_row.excluded_literal_subject.contains('static screenshots')
	assert file_row.clone_reasoning_mode == 'functional_behavior_over_literal_screen_text'
	assert file_row.atomic_parity_contract.contains('answer "')
	assert file_row.runtime_evidence_contract.contains('rejected evidence')
	assert file_row.literal_copy_blocker.contains('copied runtime labels')
	assert file_row.visual_only_rejected
	assert file_row.coverage_percent <= 60
	assert file_row.next_required_evidence.any(it.contains('state-delta'))
	assert file_row.decision_reason.contains('visual/OCR similarity was rejected')
}

fn test_functional_judgment_blocks_defaulted_functional_subject() {
	judgment := ui_clone_functional_judgment(UiCloneSubjectInput{
		target_profile: 'antigravity'
		clone_intent:   'functional_ui_clone'
	}, []UiCloneRuntimeSignal{})

	assert !judgment.ready
	assert !judgment.clone_claim_allowed
	assert !judgment.functional_subject_explicit
	assert judgment.blind_risk == 'functional_subject_defaulted_to_visual_reference'
	assert judgment.blocker == 'functional_subject_defaulted_to_visual_reference'
	assert judgment.functional_coverage_percent < 100
	assert judgment.decision_rule.contains('visual similarity is only a locator')
}

fn judgment_vexplorer_runtime_signals() []UiCloneRuntimeSignal {
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

fn judgment_row_for_component(rows []UiCloneFunctionalJudgmentRow,
	component string) UiCloneFunctionalJudgmentRow {
	for row in rows {
		if row.functional_component == component {
			return row
		}
	}
	panic('missing functional judgment row for ${component}')
}
