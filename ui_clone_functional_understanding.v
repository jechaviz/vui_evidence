module vui_evidence

pub struct UiCloneFunctionalUnderstandingRow {
pub:
	visual_profile               string
	functional_profile           string
	clone_intent                 string
	visual_region                string
	functional_region            string
	visual_component             string
	functional_component         string
	visual_locus_role            string
	functional_owner_role        string
	functional_question          string
	expected_state_delta         string
	stable_visual_anchors        []string
	runtime_data_masks           []string
	behavior_probe_affordances   []string
	accepted_evidence_kinds      []string
	rejected_evidence_kinds      []string
	nonblind_reasoning           bool
	literal_text_is_runtime_data bool
	visual_only_rejected         bool
	certification_rule           string
}

pub struct UiCloneFunctionalUnderstandingSummary {
pub:
	visual_profile            string
	functional_profile        string
	clone_intent              string
	mode                      string
	cross_profile             bool
	ready                     bool
	blocker                   string
	row_count                 int
	nonblind_row_count        int
	functional_question_count int
	behavior_probe_count      int
	runtime_data_mask_count   int
	literal_text_can_certify  bool
	visual_only_can_certify   bool
	visual_subject            string
	functional_subject        string
	reasoning_rule            string
}

pub fn ui_clone_functional_understanding(visual_reference_profile string,
	functional_target_profile string, clone_intent string) []UiCloneFunctionalUnderstandingRow {
	equivalence := ui_clone_functional_equivalence(visual_reference_profile,
		functional_target_profile, clone_intent)
	mut rows := []UiCloneFunctionalUnderstandingRow{}
	for row in equivalence {
		rows << ui_clone_functional_understanding_row(row)
	}
	return rows
}

pub fn ui_clone_functional_understanding_summary(visual_reference_profile string,
	functional_target_profile string, clone_intent string) UiCloneFunctionalUnderstandingSummary {
	equivalence := ui_clone_functional_equivalence_summary(visual_reference_profile,
		functional_target_profile, clone_intent)
	rows := ui_clone_functional_understanding(visual_reference_profile, functional_target_profile,
		clone_intent)
	nonblind := ui_clone_functional_understanding_nonblind_count(rows)
	return UiCloneFunctionalUnderstandingSummary{
		visual_profile:            equivalence.visual_profile
		functional_profile:        equivalence.functional_profile
		clone_intent:              equivalence.clone_intent
		mode:                      equivalence.mode
		cross_profile:             equivalence.cross_profile
		ready:                     equivalence.ready && rows.len > 0 && nonblind == rows.len
		blocker:                   ui_clone_functional_understanding_blocker(equivalence, rows,
			nonblind)
		row_count:                 rows.len
		nonblind_row_count:        nonblind
		functional_question_count: ui_clone_functional_understanding_question_count(rows)
		behavior_probe_count:      equivalence.behavior_probe_count
		runtime_data_mask_count:   equivalence.runtime_data_mask_count
		literal_text_can_certify:  false
		visual_only_can_certify:   false
		visual_subject:            ui_clone_functional_clone_subject(equivalence.visual_profile)
		functional_subject:        ui_clone_functional_clone_subject(equivalence.functional_profile)
		reasoning_rule:            ui_clone_functional_understanding_rule(equivalence, rows,
			nonblind)
	}
}

fn ui_clone_functional_understanding_row(row UiCloneFunctionalEquivalenceRow) UiCloneFunctionalUnderstandingRow {
	return UiCloneFunctionalUnderstandingRow{
		visual_profile:               row.visual_profile
		functional_profile:           row.functional_profile
		clone_intent:                 row.clone_intent
		visual_region:                row.visual_region
		functional_region:            row.functional_region
		visual_component:             row.visual_component
		functional_component:         row.functional_component
		visual_locus_role:            ui_clone_visual_locus_role(row)
		functional_owner_role:        ui_clone_functional_owner_role(row)
		functional_question:          ui_clone_functional_question(row.functional_component)
		expected_state_delta:         ui_clone_expected_state_delta(row)
		stable_visual_anchors:        row.stable_visual_anchors
		runtime_data_masks:           row.functional_runtime_masks
		behavior_probe_affordances:   row.behavior_probe_affordances
		accepted_evidence_kinds:      ui_clone_functional_accepted_evidence(row)
		rejected_evidence_kinds:      ui_clone_functional_rejected_evidence(row)
		nonblind_reasoning:           ui_clone_functional_row_nonblind(row)
		literal_text_is_runtime_data: row.functional_runtime_masks.len > 0
		visual_only_rejected:         true
		certification_rule:           ui_clone_functional_row_rule(row)
	}
}

fn ui_clone_visual_locus_role(row UiCloneFunctionalEquivalenceRow) string {
	if row.visual_component == row.functional_component {
		return '${row.visual_component} supplies stable geometry and the action locus for its own behavior'
	}
	return '${row.visual_component} supplies only the visible locus; it does not own ${row.functional_component} behavior'
}

fn ui_clone_functional_owner_role(row UiCloneFunctionalEquivalenceRow) string {
	return '${row.functional_component} owns commands, state deltas, data masks, and certification'
}

fn ui_clone_functional_question(component string) string {
	return match normalized_clone_value(component) {
		'window.frame' { 'Can the desktop window move, resize, minimize, maximize, close, and cooperate with tray or transparency tools?' }
		'command.center' { 'Can global command entry open, filter, select, and dispatch commands against workbench state?' }
		'path.command' { 'Can path entry change workspace roots and refresh the file surface instead of only showing text?' }
		'app.menu' { 'Can native menus dispatch real commands and mutate visible application state?' }
		'ide.bridge' { 'Can the IDE bridge open or route a workspace command to the intended workbench target?' }
		'activity.rail' { 'Can primary navigation switch views and preserve focus, active, hover, and keyboard state?' }
		'explorer.tree' { 'Can tree navigation reveal, select, rename, delete, drag, and open workspace resources?' }
		'conversation.nav' { 'Can session/project navigation change the active conversation or project scope?' }
		'editor.surface' { 'Can the editing surface apply text/model changes, selections, undo, diagnostics, webviews, and notebooks?' }
		'file.list' { 'Can the file surface select, open, preview, sort, rename, copy, move, delete, and create files?' }
		'prompt.composer' { 'Can the composer mutate prompt/model/tool/local/submit state and append session history?' }
		'status.indicators' { 'Can status slots update from workspace diagnostics, branch, remote, language, and notification events?' }
		'local.runtime' { 'Can local runtime indicators update from model availability, mode, latency, and execution state?' }
		else { 'Can this surface prove its declared role through command, action, state-delta, or live-event receipts?' }
	}
}

fn ui_clone_expected_state_delta(row UiCloneFunctionalEquivalenceRow) string {
	if row.required_behaviors.len > 0 {
		return row.required_behaviors.join('; ')
	}
	if row.behavior_probe_affordances.len > 0 {
		return row.behavior_probe_affordances.join('; ')
	}
	return 'role-specific runtime state delta'
}

fn ui_clone_functional_accepted_evidence(row UiCloneFunctionalEquivalenceRow) []string {
	mut out := [
		'command_dispatch',
		'action_receipt',
		'state_delta',
		'model_mutation',
		'live_runtime_event',
	]
	for probe in row.behavior_probe_affordances {
		ui_clone_append_unique(mut out, 'probe:${probe}')
	}
	if normalized_clone_value(row.functional_component) == 'window.frame' {
		ui_clone_append_unique(mut out, 'native_window_event')
	}
	if normalized_clone_value(row.functional_component) in ['file.list', 'explorer.tree'] {
		ui_clone_append_unique(mut out, 'file_operation_receipt')
	}
	return out
}

fn ui_clone_functional_rejected_evidence(row UiCloneFunctionalEquivalenceRow) []string {
	mut out := [
		'screenshot_similarity_without_probe',
		'ocr_text_match',
		'copied_runtime_labels',
		'visual_only_mimic',
	]
	for rule in row.anti_blind_rules {
		ui_clone_append_unique(mut out, rule)
	}
	return out
}

fn ui_clone_functional_row_nonblind(row UiCloneFunctionalEquivalenceRow) bool {
	return !row.visual_surface_missing && row.stable_visual_anchors.len > 0
		&& row.behavior_probe_count > 0 && row.functional_runtime_masks.len > 0
}

fn ui_clone_functional_row_rule(row UiCloneFunctionalEquivalenceRow) string {
	if row.visual_surface_missing {
		return 'blocked: missing visual locus for ${row.functional_component}'
	}
	return 'certify ${row.functional_component} by answering the functional question with accepted runtime evidence; copied labels and visual mimicry do not count'
}

fn ui_clone_functional_understanding_blocker(equivalence UiCloneFunctionalEquivalenceSummary,
	rows []UiCloneFunctionalUnderstandingRow, nonblind int) string {
	if !equivalence.ready {
		return equivalence.blocker
	}
	if rows.len == 0 {
		return 'functional_understanding_has_no_rows'
	}
	if nonblind != rows.len {
		return 'functional_understanding_has_blind_rows'
	}
	return ''
}

fn ui_clone_functional_understanding_rule(equivalence UiCloneFunctionalEquivalenceSummary,
	rows []UiCloneFunctionalUnderstandingRow, nonblind int) string {
	blocker := ui_clone_functional_understanding_blocker(equivalence, rows, nonblind)
	if blocker != '' {
		return 'blocked: ${blocker}'
	}
	return 'clone reasoning compares the visual locus to the functional question, then accepts only command/action/state-delta/live-event evidence'
}

fn ui_clone_functional_understanding_nonblind_count(rows []UiCloneFunctionalUnderstandingRow) int {
	mut count := 0
	for row in rows {
		if row.nonblind_reasoning {
			count++
		}
	}
	return count
}

fn ui_clone_functional_understanding_question_count(rows []UiCloneFunctionalUnderstandingRow) int {
	mut count := 0
	for row in rows {
		if row.functional_question != '' {
			count++
		}
	}
	return count
}
