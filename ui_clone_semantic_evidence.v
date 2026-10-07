module vui_evidence

pub struct UiCloneBehaviorProbeEvidenceReceipt {
pub:
	affordance string
	evidence   UiCloneRuntimeProbeEvidence
}

pub struct UiCloneSemanticEvidenceRow {
pub:
	region                       string
	component                    string
	role                         string
	stable_invariants            []string
	dynamic_data                 []string
	required_behaviors           []string
	behavior_probe_affordances   []string
	behavior_probe_passed_count  int
	behavior_probe_failed_count  int
	behavior_probe_missing_count int
	evidence_classes             []string
	evidence_sources             []string
	matched_signal_ids           []string
	literal_text_is_runtime_data bool
	visual_only_blocked          bool
	certification_status         string
	certification_rule           string
}

pub struct UiCloneSemanticEvidenceLedger {
pub:
	target_profile               string
	source_product               string
	clone_intent                 string
	mode                         string
	ready                        bool
	blind_clone_blocker          string
	nonblind_reasoning           bool
	literal_text_can_certify     bool
	surface_count                int
	stable_invariant_count       int
	dynamic_data_mask_count      int
	required_behavior_count      int
	behavior_probe_count         int
	behavior_probe_passed_count  int
	behavior_probe_failed_count  int
	behavior_probe_missing_count int
	visual_only_blocked_count    int
	functional_parity_candidate  bool
	certification_rule           string
	rows                         []UiCloneSemanticEvidenceRow
}

pub fn ui_clone_semantic_evidence_ledger(target_profile string, clone_intent string,
	signals []UiCloneRuntimeSignal) UiCloneSemanticEvidenceLedger {
	mut receipts := []UiCloneBehaviorProbeEvidenceReceipt{}
	for policy in ui_clone_behavior_probe_policies(target_profile, clone_intent) {
		receipts << UiCloneBehaviorProbeEvidenceReceipt{
			affordance: policy.affordance
			evidence:   ui_clone_runtime_evidence_for_probe(policy, signals)
		}
	}
	return ui_clone_semantic_evidence_ledger_from_probe_evidence(target_profile, clone_intent,
		receipts)
}

pub fn ui_clone_semantic_evidence_ledger_from_probe_evidence(target_profile string,
	clone_intent string, receipts []UiCloneBehaviorProbeEvidenceReceipt) UiCloneSemanticEvidenceLedger {
	contract := ui_clone_contract(target_profile, clone_intent)
	alignments := ui_clone_semantic_alignment(contract.target_profile, contract.clone_intent)
	mut rows := []UiCloneSemanticEvidenceRow{}
	for alignment in alignments {
		rows << ui_clone_semantic_evidence_row(alignment, receipts)
	}
	passed := ui_clone_semantic_evidence_passed_count(rows)
	failed := ui_clone_semantic_evidence_failed_count(rows)
	missing := ui_clone_semantic_evidence_missing_count(rows)
	visual_only := ui_clone_semantic_evidence_visual_only_count(rows)
	probe_count := ui_clone_semantic_evidence_probe_count(rows)
	nonblind := contract.reasoning_ready && rows.len > 0
		&& ui_clone_semantic_evidence_invariant_count(rows) > 0
	candidate := nonblind && probe_count > 0 && failed == 0 && missing == 0 && visual_only == 0
	return UiCloneSemanticEvidenceLedger{
		target_profile:               contract.target_profile
		source_product:               contract.source_product
		clone_intent:                 contract.clone_intent
		mode:                         contract.mode
		ready:                        contract.reasoning_ready
		blind_clone_blocker:          contract.blind_clone_blocker
		nonblind_reasoning:           nonblind
		literal_text_can_certify:     contract.mode != 'semantic_functional_clone'
		surface_count:                rows.len
		stable_invariant_count:       ui_clone_semantic_evidence_invariant_count(rows)
		dynamic_data_mask_count:      ui_clone_semantic_evidence_dynamic_count(rows)
		required_behavior_count:      ui_clone_semantic_evidence_required_behavior_count(rows)
		behavior_probe_count:         probe_count
		behavior_probe_passed_count:  passed
		behavior_probe_failed_count:  failed
		behavior_probe_missing_count: missing
		visual_only_blocked_count:    visual_only
		functional_parity_candidate:  candidate
		certification_rule:           ui_clone_semantic_evidence_rule(contract, candidate)
		rows:                         rows
	}
}

fn ui_clone_semantic_evidence_row(alignment UiCloneSemanticAlignmentRow,
	receipts []UiCloneBehaviorProbeEvidenceReceipt) UiCloneSemanticEvidenceRow {
	mut passed := 0
	mut failed := 0
	mut missing := 0
	mut visual_only := false
	mut classes := []string{}
	mut sources := []string{}
	mut signal_ids := []string{}
	for affordance in alignment.behavior_probe_affordances {
		evidence := ui_clone_semantic_evidence_for_affordance(receipts, affordance)
		if !evidence.found {
			missing++
			continue
		}
		ui_clone_append_unique(mut classes, evidence.semantic_class)
		ui_clone_append_unique(mut sources, evidence.source)
		ui_clone_append_unique(mut signal_ids, evidence.matched_signal_id)
		if evidence.ok {
			passed++
		} else {
			failed++
			if evidence.semantic_class == 'visual_mimic' {
				visual_only = true
			}
		}
	}
	return UiCloneSemanticEvidenceRow{
		region:                       alignment.region
		component:                    alignment.component
		role:                         alignment.role
		stable_invariants:            alignment.match_invariants
		dynamic_data:                 alignment.mask_runtime_data
		required_behaviors:           alignment.required_behaviors
		behavior_probe_affordances:   alignment.behavior_probe_affordances
		behavior_probe_passed_count:  passed
		behavior_probe_failed_count:  failed
		behavior_probe_missing_count: missing
		evidence_classes:             classes
		evidence_sources:             sources
		matched_signal_ids:           signal_ids
		literal_text_is_runtime_data: alignment.dynamic_content
		visual_only_blocked:          visual_only
		certification_status:         ui_clone_semantic_evidence_status(passed, failed, missing,
			visual_only)
		certification_rule:           alignment.certification_rule
	}
}

fn ui_clone_semantic_evidence_for_affordance(receipts []UiCloneBehaviorProbeEvidenceReceipt,
	affordance string) UiCloneRuntimeProbeEvidence {
	clean := normalized_clone_value(affordance)
	for receipt in receipts {
		if normalized_clone_value(receipt.affordance) == clean {
			return receipt.evidence
		}
	}
	return UiCloneRuntimeProbeEvidence{
		reason: 'semantic_evidence_missing_${affordance}'
	}
}

fn ui_clone_semantic_evidence_status(passed int, failed int, missing int, visual_only bool) string {
	if visual_only {
		return 'visual_only_rejected'
	}
	if failed > 0 {
		return 'failed'
	}
	if missing > 0 {
		return 'pending_probe'
	}
	if passed > 0 {
		return 'ready'
	}
	return 'structural_only'
}

fn ui_clone_semantic_evidence_rule(contract UiCloneContract, candidate bool) string {
	if contract.mode != 'semantic_functional_clone' {
		return 'visual reference can be certified by segmented pixels'
	}
	if contract.blind_clone_blocker != '' {
		return 'blocked: target profile has no semantic functional contract'
	}
	if candidate {
		return 'certified by semantic surfaces plus atomic behavior evidence'
	}
	return 'not certified: every required behavior needs functional runtime evidence'
}

fn ui_clone_append_unique(mut values []string, value string) {
	clean := value.trim_space()
	if clean != '' && clean !in values {
		values << clean
	}
}

fn ui_clone_semantic_evidence_invariant_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.stable_invariants.len
	}
	return count
}

fn ui_clone_semantic_evidence_dynamic_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.dynamic_data.len
	}
	return count
}

fn ui_clone_semantic_evidence_required_behavior_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.required_behaviors.len
	}
	return count
}

fn ui_clone_semantic_evidence_probe_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_affordances.len
	}
	return count
}

fn ui_clone_semantic_evidence_passed_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_passed_count
	}
	return count
}

fn ui_clone_semantic_evidence_failed_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_failed_count
	}
	return count
}

fn ui_clone_semantic_evidence_missing_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		count += row.behavior_probe_missing_count
	}
	return count
}

fn ui_clone_semantic_evidence_visual_only_count(rows []UiCloneSemanticEvidenceRow) int {
	mut count := 0
	for row in rows {
		if row.visual_only_blocked {
			count++
		}
	}
	return count
}
