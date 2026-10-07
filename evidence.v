module vui_evidence

pub enum EvidenceClass {
	visual
	structural
	behavioral
	semantic
	telemetry
}

pub enum Verdict {
	missing
	passed
	failed
	blocked
}

pub struct SurfaceRequirement {
pub:
	surface           string
	component         string
	stable_invariants []string
	dynamic_fields    []string
	behaviors         []string
	allow_visual_only bool
}

pub struct ProbeReceipt {
pub:
	id       string
	surface  string
	behavior string
	class    EvidenceClass
	ok       bool
	source   string
	note     string
}

pub struct SurfaceEvidence {
pub:
	surface            string
	component          string
	required_behaviors int
	passed              int
	failed              int
	missing             int
	visual_only_blocked bool
	sources             []string
	receipt_ids         []string
	verdict             Verdict
}

pub struct Ledger {
pub:
	rows          []SurfaceEvidence
	passed        int
	failed        int
	missing       int
	blocked       int
	certified     bool
}

pub fn evaluate(requirement SurfaceRequirement, receipts []ProbeReceipt) SurfaceEvidence {
	mut passed := 0
	mut failed := 0
	mut missing := 0
	mut visual_only_blocked := false
	mut sources := []string{}
	mut ids := []string{}
	for behavior in requirement.behaviors {
		matches := receipts_for(requirement.surface, behavior, receipts)
		if matches.len == 0 {
			missing++
			continue
		}
		mut behavior_ok := false
		for receipt in matches {
			append_unique(mut sources, receipt.source)
			append_unique(mut ids, receipt.id)
			if receipt.class == .visual && !requirement.allow_visual_only {
				visual_only_blocked = true
				continue
			}
			if receipt.ok {
				behavior_ok = true
			}
		}
		if behavior_ok {
			passed++
		} else {
			failed++
		}
	}
	return SurfaceEvidence{
		surface:            requirement.surface
		component:          requirement.component
		required_behaviors: requirement.behaviors.len
		passed:              passed
		failed:              failed
		missing:             missing
		visual_only_blocked: visual_only_blocked
		sources:             sources
		receipt_ids:         ids
		verdict:             verdict_for(passed, failed, missing, visual_only_blocked)
	}
}

pub fn build_ledger(requirements []SurfaceRequirement, receipts []ProbeReceipt) Ledger {
	mut rows := []SurfaceEvidence{cap: requirements.len}
	mut passed := 0
	mut failed := 0
	mut missing := 0
	mut blocked := 0
	for requirement in requirements {
		row := evaluate(requirement, receipts)
		rows << row
		match row.verdict {
			.passed { passed++ }
			.failed { failed++ }
			.missing { missing++ }
			.blocked { blocked++ }
		}
	}
	return Ledger{
		rows:      rows
		passed:    passed
		failed:    failed
		missing:   missing
		blocked:   blocked
		certified: rows.len > 0 && failed == 0 && missing == 0 && blocked == 0
	}
}

fn receipts_for(surface string, behavior string, receipts []ProbeReceipt) []ProbeReceipt {
	mut out := []ProbeReceipt{}
	for receipt in receipts {
		if receipt.surface == surface && receipt.behavior == behavior {
			out << receipt
		}
	}
	return out
}

fn verdict_for(passed int, failed int, missing int, blocked bool) Verdict {
	if blocked {
		return .blocked
	}
	if failed > 0 {
		return .failed
	}
	if missing > 0 {
		return .missing
	}
	if passed > 0 {
		return .passed
	}
	return .missing
}

fn append_unique(mut values []string, value string) {
	clean := value.trim_space()
	if clean != '' && clean !in values {
		values << clean
	}
}
