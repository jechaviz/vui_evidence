module vui_evidence

fn test_behavioral_evidence_certifies_surface() {
	requirement := SurfaceRequirement{
		surface:   'mission_bar'
		component: 'input'
		behaviors: ['submit', 'focus']
	}
	receipts := [
		ProbeReceipt{id: 'r1', surface: 'mission_bar', behavior: 'submit', class: .behavioral, ok: true, source: 'runtime'},
		ProbeReceipt{id: 'r2', surface: 'mission_bar', behavior: 'focus', class: .telemetry, ok: true, source: 'runtime'},
	]
	row := evaluate(requirement, receipts)
	assert row.verdict == .passed
	assert row.passed == 2
}

fn test_visual_only_does_not_certify_behavior_by_default() {
	requirement := SurfaceRequirement{
		surface:   'agent_dock'
		component: 'panel'
		behaviors: ['open']
	}
	receipts := [
		ProbeReceipt{id: 'r1', surface: 'agent_dock', behavior: 'open', class: .visual, ok: true, source: 'screenshot'},
	]
	row := evaluate(requirement, receipts)
	assert row.verdict == .blocked
}
