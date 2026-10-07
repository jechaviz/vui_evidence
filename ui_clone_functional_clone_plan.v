module vui_evidence

pub struct UiCloneFunctionalClonePlan {
pub:
	visual_profile              string
	functional_profile          string
	clone_intent                string
	mode                        string
	cross_profile               bool
	ready                       bool
	blocker                     string
	visual_reference_subject    string
	functional_target_subject   string
	visual_reference_role       string
	functional_target_role      string
	clone_goal                  string
	authority_rule              string
	visual_owned_components     []string
	functional_owned_components []string
	runtime_data_masks          []string
	behavior_probe_affordances  []string
	accepted_evidence_kinds     []string
	rejected_evidence_kinds     []string
	behavior_probe_count        int
	background_safe_probe_count int
	literal_text_can_certify    bool
	visual_only_can_certify     bool
	certification_gate          string
}

pub fn ui_clone_functional_clone_plan(visual_reference_profile string,
	functional_target_profile string, clone_intent string) UiCloneFunctionalClonePlan {
	scope := ui_clone_scope_contract(visual_reference_profile, functional_target_profile,
		clone_intent)
	summary := ui_clone_functional_equivalence_summary(visual_reference_profile,
		functional_target_profile, clone_intent)
	return UiCloneFunctionalClonePlan{
		visual_profile:              scope.visual_profile
		functional_profile:          scope.functional_profile
		clone_intent:                scope.clone_intent
		mode:                        scope.mode
		cross_profile:               scope.cross_profile
		ready:                       scope.ready && summary.ready
		blocker:                     ui_clone_functional_clone_plan_blocker(scope, summary)
		visual_reference_subject:    ui_clone_functional_clone_subject(scope.visual_profile)
		functional_target_subject:   ui_clone_functional_clone_subject(scope.functional_profile)
		visual_reference_role:       scope.visual_reference_role
		functional_target_role:      scope.functional_target_role
		clone_goal:                  ui_clone_functional_clone_goal(scope)
		authority_rule:              ui_clone_functional_clone_authority_rule(scope)
		visual_owned_components:     ui_clone_functional_clone_visual_components(summary.rows)
		functional_owned_components: ui_clone_functional_clone_functional_components(summary.rows)
		runtime_data_masks:          ui_clone_functional_clone_masks(summary.rows)
		behavior_probe_affordances:  ui_clone_functional_clone_probes(summary.rows)
		accepted_evidence_kinds:     scope.accepted_evidence_kinds
		rejected_evidence_kinds:     ui_clone_functional_clone_rejected_evidence(scope)
		behavior_probe_count:        summary.behavior_probe_count
		background_safe_probe_count: summary.background_safe_probe_count
		literal_text_can_certify:    false
		visual_only_can_certify:     false
		certification_gate:          ui_clone_functional_clone_gate(scope, summary)
	}
}

fn ui_clone_functional_clone_plan_blocker(scope UiCloneScopeContract,
	summary UiCloneFunctionalEquivalenceSummary) string {
	if !scope.ready {
		return scope.blocker
	}
	if !summary.ready {
		return summary.blocker
	}
	return ''
}

fn ui_clone_functional_clone_subject(profile string) string {
	return match canonical_clone_profile(profile) {
		'vscode' { 'VS Code workbench contract' }
		'vexplorer' { 'VExplorer desktop file-workbench contract' }
		'antigravity' { 'Antigravity desktop shell reference' }
		else { 'unknown UI product contract' }
	}
}

fn ui_clone_functional_clone_goal(scope UiCloneScopeContract) string {
	if scope.mode != 'semantic_functional_clone' {
		return 'compare visual pixels against the selected reference'
	}
	if scope.cross_profile {
		return 'use ${scope.visual_profile} shape as a native visual shell while ${scope.functional_profile} supplies behavior, state, and runtime data truth'
	}
	return 'match ${scope.functional_profile} stable visual anchors and functional behavior without copying runtime text'
}

fn ui_clone_functional_clone_authority_rule(scope UiCloneScopeContract) string {
	if scope.cross_profile {
		return 'visual profile owns geometry and affordance loci; functional profile owns actions, state deltas, data masks, and certification'
	}
	return 'one profile owns both stable visual anchors and functional behavior, while runtime text remains data'
}

fn ui_clone_functional_clone_visual_components(rows []UiCloneFunctionalEquivalenceRow) []string {
	mut out := []string{}
	for row in rows {
		if row.visual_component != '' {
			ui_clone_append_unique(mut out, row.visual_component)
		}
	}
	return out
}

fn ui_clone_functional_clone_functional_components(rows []UiCloneFunctionalEquivalenceRow) []string {
	mut out := []string{}
	for row in rows {
		ui_clone_append_unique(mut out, row.functional_component)
	}
	return out
}

fn ui_clone_functional_clone_masks(rows []UiCloneFunctionalEquivalenceRow) []string {
	mut out := []string{}
	for row in rows {
		for item in row.functional_runtime_masks {
			ui_clone_append_unique(mut out, item)
		}
	}
	return out
}

fn ui_clone_functional_clone_probes(rows []UiCloneFunctionalEquivalenceRow) []string {
	mut out := []string{}
	for row in rows {
		for item in row.behavior_probe_affordances {
			ui_clone_append_unique(mut out, item)
		}
	}
	return out
}

fn ui_clone_functional_clone_rejected_evidence(scope UiCloneScopeContract) []string {
	mut out := []string{}
	for item in scope.rejected_evidence_kinds {
		ui_clone_append_unique(mut out, item)
	}
	ui_clone_append_unique(mut out, 'copied_runtime_labels')
	ui_clone_append_unique(mut out, 'visual_clone_without_functional_subject')
	return out
}

fn ui_clone_functional_clone_gate(scope UiCloneScopeContract,
	summary UiCloneFunctionalEquivalenceSummary) string {
	if !scope.ready {
		return 'blocked: ${scope.blocker}'
	}
	if !summary.ready {
		return 'blocked: ${summary.blocker}'
	}
	return 'require explicit visual subject, explicit functional subject, mapped surfaces, masked runtime data, and atomic behavior receipts'
}
