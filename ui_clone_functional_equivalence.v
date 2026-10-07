module vui_evidence

pub struct UiCloneFunctionalEquivalenceRow {
pub:
	visual_profile              string
	functional_profile          string
	clone_intent                string
	cross_profile               bool
	visual_region               string
	visual_component            string
	visual_role                 string
	functional_region           string
	functional_component        string
	functional_role             string
	equivalence_role            string
	substitution_kind           string
	visual_authority            string
	functional_authority        string
	geometry_required           bool
	literal_text_can_certify    bool
	visual_only_can_certify     bool
	visual_surface_missing      bool
	stable_visual_anchors       []string
	functional_runtime_masks    []string
	required_behaviors          []string
	behavior_probe_affordances  []string
	behavior_probe_count        int
	background_safe_probe_count int
	certification_gate          string
	anti_blind_rules            []string
}

pub struct UiCloneFunctionalEquivalenceSummary {
pub:
	visual_profile                    string
	functional_profile                string
	clone_intent                      string
	mode                              string
	cross_profile                     bool
	ready                             bool
	blocker                           string
	visual_authority                  string
	functional_authority              string
	row_count                         int
	mapped_surface_count              int
	unmapped_functional_surface_count int
	behavior_probe_count              int
	background_safe_probe_count       int
	runtime_data_mask_count           int
	literal_text_can_certify          bool
	visual_only_can_certify           bool
	certification_rule                string
	rows                              []UiCloneFunctionalEquivalenceRow
}

pub fn ui_clone_functional_equivalence(visual_reference_profile string,
	functional_target_profile string, clone_intent string) []UiCloneFunctionalEquivalenceRow {
	scope := ui_clone_scope_contract(visual_reference_profile, functional_target_profile,
		clone_intent)
	if !scope.ready || scope.mode != 'semantic_functional_clone' {
		return []UiCloneFunctionalEquivalenceRow{}
	}
	functional_rows := ui_clone_semantic_alignment(scope.functional_profile, scope.clone_intent)
	visual_surfaces := ui_clone_semantic_surfaces(scope.visual_profile, scope.clone_intent)
	mut rows := []UiCloneFunctionalEquivalenceRow{}
	for functional in functional_rows {
		visual := ui_clone_equivalent_visual_surface(scope.visual_profile, scope.functional_profile,
			functional.component, visual_surfaces)
		rows << ui_clone_functional_equivalence_row(scope, visual, functional)
	}
	return rows
}

pub fn ui_clone_functional_equivalence_summary(visual_reference_profile string,
	functional_target_profile string, clone_intent string) UiCloneFunctionalEquivalenceSummary {
	scope := ui_clone_scope_contract(visual_reference_profile, functional_target_profile,
		clone_intent)
	rows := ui_clone_functional_equivalence(visual_reference_profile, functional_target_profile,
		clone_intent)
	unmapped := ui_clone_functional_equivalence_unmapped_count(rows)
	behavior_probes := ui_clone_functional_equivalence_probe_count(rows)
	return UiCloneFunctionalEquivalenceSummary{
		visual_profile:                    scope.visual_profile
		functional_profile:                scope.functional_profile
		clone_intent:                      scope.clone_intent
		mode:                              scope.mode
		cross_profile:                     scope.cross_profile
		ready:                             scope.ready && rows.len > 0 && unmapped == 0
		blocker:                           ui_clone_functional_equivalence_blocker(scope, rows,
			unmapped)
		visual_authority:                  'visual reference supplies geometry, stable anchors, and affordance loci only'
		functional_authority:              'functional target supplies behavior probes, runtime state, and dynamic data masks'
		row_count:                         rows.len
		mapped_surface_count:              rows.len - unmapped
		unmapped_functional_surface_count: unmapped
		behavior_probe_count:              behavior_probes
		background_safe_probe_count:       ui_clone_functional_equivalence_background_probe_count(rows)
		runtime_data_mask_count:           ui_clone_functional_equivalence_mask_count(rows)
		literal_text_can_certify:          false
		visual_only_can_certify:           false
		certification_rule:                ui_clone_functional_equivalence_rule(scope,
			behavior_probes, unmapped)
		rows:                              rows
	}
}

pub fn ui_clone_functional_equivalence_for_component(visual_reference_profile string,
	functional_target_profile string, clone_intent string,
	functional_component string) ?UiCloneFunctionalEquivalenceRow {
	clean := normalized_clone_value(functional_component)
	for row in ui_clone_functional_equivalence(visual_reference_profile, functional_target_profile,
		clone_intent) {
		if normalized_clone_value(row.functional_component) == clean {
			return row
		}
	}
	return none
}

fn ui_clone_functional_equivalence_row(scope UiCloneScopeContract,
	visual ?UiCloneSemanticSurface, functional UiCloneSemanticAlignmentRow) UiCloneFunctionalEquivalenceRow {
	visual_missing := visual == none
	visual_surface := visual or {
		UiCloneSemanticSurface{
			region:    ''
			component: ''
			role:      ''
		}
	}
	mut runtime_masks := []string{}
	for item in functional.mask_runtime_data {
		ui_clone_append_unique(mut runtime_masks, item)
	}
	for item in visual_surface.dynamic_data {
		ui_clone_append_unique(mut runtime_masks, item)
	}
	mut anchors := []string{}
	for item in visual_surface.stable_invariants {
		ui_clone_append_unique(mut anchors, item)
	}
	for item in functional.match_invariants {
		ui_clone_append_unique(mut anchors, item)
	}
	return UiCloneFunctionalEquivalenceRow{
		visual_profile:              scope.visual_profile
		functional_profile:          scope.functional_profile
		clone_intent:                scope.clone_intent
		cross_profile:               scope.cross_profile
		visual_region:               visual_surface.region
		visual_component:            visual_surface.component
		visual_role:                 visual_surface.role
		functional_region:           functional.region
		functional_component:        functional.component
		functional_role:             functional.role
		equivalence_role:            ui_clone_equivalence_role(scope, visual_surface,
			functional)
		substitution_kind:           ui_clone_equivalence_substitution_kind(scope,
			visual_missing)
		visual_authority:            'geometry_and_affordance_locus'
		functional_authority:        'runtime_behavior_state_and_dynamic_data'
		geometry_required:           functional.compare_geometry
		literal_text_can_certify:    false
		visual_only_can_certify:     false
		visual_surface_missing:      visual_missing
		stable_visual_anchors:       anchors
		functional_runtime_masks:    runtime_masks
		required_behaviors:          functional.required_behaviors
		behavior_probe_affordances:  functional.behavior_probe_affordances
		behavior_probe_count:        functional.behavior_probe_count
		background_safe_probe_count: functional.background_safe_probe_count
		certification_gate:          ui_clone_equivalence_row_gate(visual_missing,
			functional)
		anti_blind_rules:            ui_clone_equivalence_anti_blind_rules(functional,
			visual_surface)
	}
}

fn ui_clone_equivalent_visual_surface(visual_profile string, functional_profile string,
	functional_component string, visual_surfaces []UiCloneSemanticSurface) ?UiCloneSemanticSurface {
	visual_component := ui_clone_equivalent_visual_component(visual_profile, functional_profile,
		functional_component)
	return ui_clone_visual_surface_for_component(visual_surfaces, visual_component)
}

fn ui_clone_equivalent_visual_component(visual_profile string, functional_profile string,
	functional_component string) string {
	visual := canonical_clone_profile(visual_profile)
	functional := canonical_clone_profile(functional_profile)
	component := normalized_clone_value(functional_component)
	if visual == functional {
		return component
	}
	return match '${visual}->${functional}:${component}' {
		'antigravity->vexplorer:window.frame' { 'window.frame' }
		'antigravity->vexplorer:path.command' { 'ide.bridge' }
		'antigravity->vexplorer:activity.rail' { 'conversation.nav' }
		'antigravity->vexplorer:explorer.tree' { 'conversation.nav' }
		'antigravity->vexplorer:file.list' { 'prompt.composer' }
		'antigravity->vexplorer:status.indicators' { 'local.runtime' }
		'antigravity->vscode:window.frame' { 'window.frame' }
		'antigravity->vscode:command.center' { 'ide.bridge' }
		'antigravity->vscode:activity.rail' { 'conversation.nav' }
		'antigravity->vscode:explorer.tree' { 'conversation.nav' }
		'antigravity->vscode:editor.surface' { 'prompt.composer' }
		'antigravity->vscode:status.indicators' { 'local.runtime' }
		'vexplorer->vscode:window.frame' { 'window.frame' }
		'vexplorer->vscode:command.center' { 'path.command' }
		'vexplorer->vscode:activity.rail' { 'activity.rail' }
		'vexplorer->vscode:explorer.tree' { 'explorer.tree' }
		'vexplorer->vscode:editor.surface' { 'file.list' }
		'vexplorer->vscode:status.indicators' { 'status.indicators' }
		'vscode->vexplorer:window.frame' { 'window.frame' }
		'vscode->vexplorer:path.command' { 'command.center' }
		'vscode->vexplorer:activity.rail' { 'activity.rail' }
		'vscode->vexplorer:explorer.tree' { 'explorer.tree' }
		'vscode->vexplorer:file.list' { 'editor.surface' }
		'vscode->vexplorer:status.indicators' { 'status.indicators' }
		'vexplorer->antigravity:window.frame' { 'window.frame' }
		'vexplorer->antigravity:app.menu' { 'path.command' }
		'vexplorer->antigravity:ide.bridge' { 'path.command' }
		'vexplorer->antigravity:conversation.nav' { 'explorer.tree' }
		'vexplorer->antigravity:prompt.composer' { 'file.list' }
		'vexplorer->antigravity:local.runtime' { 'status.indicators' }
		'vscode->antigravity:window.frame' { 'window.frame' }
		'vscode->antigravity:app.menu' { 'command.center' }
		'vscode->antigravity:ide.bridge' { 'command.center' }
		'vscode->antigravity:conversation.nav' { 'explorer.tree' }
		'vscode->antigravity:prompt.composer' { 'editor.surface' }
		'vscode->antigravity:local.runtime' { 'status.indicators' }
		else { component }
	}
}

fn ui_clone_visual_surface_for_component(surfaces []UiCloneSemanticSurface,
	component string) ?UiCloneSemanticSurface {
	clean := normalized_clone_value(component)
	for surface in surfaces {
		if normalized_clone_value(surface.component) == clean {
			return surface
		}
	}
	return none
}

fn ui_clone_equivalence_role(scope UiCloneScopeContract, visual UiCloneSemanticSurface,
	functional UiCloneSemanticAlignmentRow) string {
	if visual.component == '' {
		return 'missing visual locus for ${functional.component}'
	}
	if !scope.cross_profile {
		return 'direct ${functional.role}'
	}
	return '${visual.component} supplies the visible locus for ${functional.component}; ${functional.component} keeps behavior ownership'
}

fn ui_clone_equivalence_substitution_kind(scope UiCloneScopeContract, visual_missing bool) string {
	if visual_missing {
		return 'blocked_missing_visual_locus'
	}
	if scope.cross_profile {
		return 'semantic_cross_profile_substitution'
	}
	return 'direct_profile_surface'
}

fn ui_clone_equivalence_row_gate(visual_missing bool,
	functional UiCloneSemanticAlignmentRow) string {
	if visual_missing {
		return 'blocked: functional surface ${functional.component} has no visual affordance locus'
	}
	if functional.behavior_probe_count > 0 {
		return 'require stable visual locus plus ${functional.behavior_probe_count} functional behavior probe(s); copied labels do not count'
	}
	return 'require stable visual locus and semantic role; copied runtime text does not count'
}

fn ui_clone_equivalence_anti_blind_rules(functional UiCloneSemanticAlignmentRow,
	visual UiCloneSemanticSurface) []string {
	mut rules := [
		'do not certify functional parity from screenshot similarity alone',
		'do not copy OCR/runtime labels as proof of behavior',
		'require atomic behavior evidence owned by ${functional.component}',
	]
	if visual.component != '' && visual.component != functional.component {
		rules << '${visual.component} is only a visual locus; ${functional.component} owns behavior and state'
	}
	if functional.mask_runtime_data.len > 0 {
		rules << 'mask functional runtime data: ${functional.mask_runtime_data.join(', ')}'
	}
	return rules
}

fn ui_clone_functional_equivalence_unmapped_count(rows []UiCloneFunctionalEquivalenceRow) int {
	mut count := 0
	for row in rows {
		if row.visual_surface_missing {
			count++
		}
	}
	return count
}

fn ui_clone_functional_equivalence_probe_count(rows []UiCloneFunctionalEquivalenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_count
	}
	return count
}

fn ui_clone_functional_equivalence_background_probe_count(rows []UiCloneFunctionalEquivalenceRow) int {
	mut count := 0
	for row in rows {
		count += row.background_safe_probe_count
	}
	return count
}

fn ui_clone_functional_equivalence_mask_count(rows []UiCloneFunctionalEquivalenceRow) int {
	mut count := 0
	for row in rows {
		count += row.functional_runtime_masks.len
	}
	return count
}

fn ui_clone_functional_equivalence_blocker(scope UiCloneScopeContract,
	rows []UiCloneFunctionalEquivalenceRow, unmapped int) string {
	if !scope.ready {
		return scope.blocker
	}
	if rows.len == 0 {
		return 'functional_equivalence_has_no_semantic_rows'
	}
	if unmapped > 0 {
		return 'functional_equivalence_has_unmapped_visual_loci'
	}
	return ''
}

fn ui_clone_functional_equivalence_rule(scope UiCloneScopeContract, behavior_probes int,
	unmapped int) string {
	if !scope.ready {
		return 'blocked: ${scope.blocker}'
	}
	if unmapped > 0 {
		return 'blocked: every functional surface needs an explicit visual locus before QA can compare it'
	}
	if behavior_probes == 0 {
		return 'blocked: functional equivalence needs atomic behavior probes'
	}
	return 'certify by explicit visual-to-functional equivalence, masked runtime text, and atomic behavior receipts'
}
